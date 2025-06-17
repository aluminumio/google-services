require 'google/apis/docs_v1'
require 'google/apis/drive_v3'

module GoogleServices
  class Docs < Base
    API_SCOPES = [
      'https://www.googleapis.com/auth/documents',
      'https://www.googleapis.com/auth/drive'
    ].freeze

    def initialize(credentials)
      super(credentials)
      @docs_service = Google::Apis::DocsV1::DocsService.new
      @drive_service = Google::Apis::DriveV3::DriveService.new
    end

    def create(title, content: nil, folder: nil)
      with_error_handling do
        authorize_services(@docs_service, @drive_service, scopes: API_SCOPES)
        
        # Create the document
        document = Google::Apis::DocsV1::Document.new(title: title)
        doc = @docs_service.create_document(document)
        
        # Add content if provided
        if content
          requests = build_content_requests(content)
          @docs_service.batch_update_document(doc.document_id, 
            Google::Apis::DocsV1::BatchUpdateDocumentRequest.new(requests: requests)) if requests.any?
        end
        
        # Move to folder if specified
        if folder
          folder_id = find_or_create_folder(folder)
          move_to_folder(doc.document_id, folder_id) if folder_id
        end
        
        # Get the document URL and metadata
        file = @drive_service.get_file(doc.document_id, fields: 'webViewLink,createdTime,modifiedTime')
        
        Document.new(
          id: doc.document_id,
          title: doc.title,
          url: file.web_view_link,
          created_at: file.created_time,
          modified_at: file.modified_time
        )
      end
    end

    def find(document_id)
      with_error_handling do
        authorize_services(@docs_service, @drive_service, scopes: API_SCOPES)
        
        doc = @docs_service.get_document(document_id)
        file = @drive_service.get_file(document_id, fields: 'webViewLink,createdTime,modifiedTime')
        
        Document.new(
          id: doc.document_id,
          title: doc.title,
          url: file.web_view_link,
          created_at: file.created_time,
          modified_at: file.modified_time
        )
      end
    end

    def update(document_id, content)
      with_error_handling do
        authorize_services(@docs_service, @drive_service, scopes: API_SCOPES)
        
        requests = build_content_requests(content)
        
        # Clear existing content first
        clear_requests = [{
          delete_content_range: {
            range: {
              start_index: 1,
              end_index: get_document_end_index(document_id)
            }
          }
        }]
        
        # Execute clear and then insert new content
        @docs_service.batch_update_document(document_id, 
          Google::Apis::DocsV1::BatchUpdateDocumentRequest.new(requests: clear_requests))
        
        @docs_service.batch_update_document(document_id, 
          Google::Apis::DocsV1::BatchUpdateDocumentRequest.new(requests: requests))
        
        find(document_id)
      end
    end

    def list(folder: nil, limit: 100)
      with_error_handling do
        authorize_services(@docs_service, @drive_service, scopes: API_SCOPES)
        
        query_parts = ["mimeType='application/vnd.google-apps.document'", "trashed=false"]
        
        if folder
          folder_id = find_folder(folder)
          query_parts << "'#{folder_id}' in parents" if folder_id
        end
        
        response = @drive_service.list_files(
          q: query_parts.join(' and '),
          fields: 'files(id,name,webViewLink,createdTime,modifiedTime)',
          page_size: limit
        )
        
        response.files.map do |file|
          Document.new(
            id: file.id,
            title: file.name,
            url: file.web_view_link,
            created_at: file.created_time,
            modified_at: file.modified_time
          )
        end
      end
    end

    def delete(document_id)
      with_error_handling do
        authorize_services(@docs_service, @drive_service, scopes: API_SCOPES)
        @drive_service.delete_file(document_id)
        true
      end
    end

    # Folder operations
    def list_folders(parent_folder: nil, limit: 100)
      with_error_handling do
        authorize_services(@docs_service, @drive_service, scopes: API_SCOPES)
        
        query_parts = ["mimeType='application/vnd.google-apps.folder'", "trashed=false"]
        
        if parent_folder
          parent_id = find_folder(parent_folder)
          query_parts << "'#{parent_id}' in parents" if parent_id
        end
        
        response = @drive_service.list_files(
          q: query_parts.join(' and '),
          fields: 'files(id,name,createdTime,modifiedTime,parents)',
          page_size: limit,
          order_by: 'name'
        )
        
        response.files.map do |file|
          Folder.new(
            id: file.id,
            name: file.name,
            created_at: file.created_time,
            modified_at: file.modified_time,
            parent_ids: file.parents || []
          )
        end
      end
    end

    def list_folder_contents(folder_name, limit: 100)
      with_error_handling do
        authorize_services(@docs_service, @drive_service, scopes: API_SCOPES)
        
        folder_id = find_folder(folder_name)
        raise NotFoundError, "Folder '#{folder_name}' not found" unless folder_id
        
        query = "'#{folder_id}' in parents and trashed=false"
        
        response = @drive_service.list_files(
          q: query,
          fields: 'files(id,name,mimeType,webViewLink,createdTime,modifiedTime)',
          page_size: limit,
          order_by: 'folder,name'
        )
        
        response.files.map do |file|
          if file.mime_type == 'application/vnd.google-apps.folder'
            Folder.new(
              id: file.id,
              name: file.name,
              created_at: file.created_time,
              modified_at: file.modified_time,
              parent_ids: [folder_id]
            )
          else
            Document.new(
              id: file.id,
              title: file.name,
              url: file.web_view_link,
              created_at: file.created_time,
              modified_at: file.modified_time
            )
          end
        end
      end
    end

    def create_folder(folder_name, parent_folder: nil)
      with_error_handling do
        authorize_services(@docs_service, @drive_service, scopes: API_SCOPES)
        
        # Check if folder already exists
        existing_id = find_folder(folder_name)
        if existing_id
          raise ApiError, "Folder '#{folder_name}' already exists"
        end
        
        folder = Google::Apis::DriveV3::File.new
        folder.name = folder_name
        folder.mime_type = 'application/vnd.google-apps.folder'
        
        if parent_folder
          parent_id = find_folder(parent_folder)
          raise NotFoundError, "Parent folder '#{parent_folder}' not found" unless parent_id
          folder.parents = [parent_id]
        end
        
        created_folder = @drive_service.create_file(
          folder, 
          fields: 'id,name,createdTime,modifiedTime,parents'
        )
        
        Folder.new(
          id: created_folder.id,
          name: created_folder.name,
          created_at: created_folder.created_time,
          modified_at: created_folder.modified_time,
          parent_ids: created_folder.parents || []
        )
      end
    end

    def delete_folder(folder_name, force: false)
      with_error_handling do
        authorize_services(@docs_service, @drive_service, scopes: API_SCOPES)
        
        folder_id = find_folder(folder_name)
        raise NotFoundError, "Folder '#{folder_name}' not found" unless folder_id
        
        # Check if folder has contents
        unless force
          contents = list_folder_contents(folder_name, limit: 1)
          unless contents.empty?
            raise ApiError, "Folder '#{folder_name}' is not empty. Use force: true to delete anyway."
          end
        end
        
        @drive_service.delete_file(folder_id)
        true
      end
    end

    private

    def build_content_requests(content)
      [{
        insert_text: {
          location: { index: 1 },
          text: content
        }
      }]
    end

    def find_or_create_folder(folder_name)
      existing_id = find_folder(folder_name)
      return existing_id if existing_id
      
      # Create new folder
      folder = Google::Apis::DriveV3::File.new
      folder.name = folder_name
      folder.mime_type = 'application/vnd.google-apps.folder'
      
      created_folder = @drive_service.create_file(folder, fields: 'id')
      created_folder.id
    end

    def find_folder(folder_name)
      query = "name='#{folder_name}' and mimeType='application/vnd.google-apps.folder' and trashed=false"
      response = @drive_service.list_files(q: query, fields: 'files(id)', page_size: 1)
      response.files.first&.id
    end

    def move_to_folder(file_id, folder_id)
      # Get current parents
      file = @drive_service.get_file(file_id, fields: 'parents')
      previous_parents = file.parents&.join(',') || ''
      
      # Move to new folder
      @drive_service.update_file(file_id, 
        add_parents: folder_id,
        remove_parents: previous_parents,
        fields: 'id, parents')
    end

    def get_document_end_index(document_id)
      doc = @docs_service.get_document(document_id)
      doc.body.content.last.end_index || 1
    end
  end
end 