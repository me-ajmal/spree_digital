module Spree
  module Admin
    class DigitalsController < ResourceController
      require 'streamio-ffmpeg'
      belongs_to "spree/product", :find_by => :slug
      before_action :authorize_admin, only: :index

      def create
        invoke_callbacks(:create, :before)
        @object.attributes = permitted_resource_params
        @object.attributes = add_additional_paramas if params[:digital][:attachment]

        if @object.valid?
          invoke_callbacks(:create, :before)
          @object.attributes = permitted_resource_params
          if @object.save
            invoke_callbacks(:create, :after)
            video_url = Rails.application.routes.url_helpers.rails_blob_path(@object.attachment, only_path: true)
            video_info = FFMPEG::Movie.new("https://stagining-celebrity-fans.herokuapp.com/"+video_url)
            video_duration = video_info.duration
            if(video_duration < 10)
              if !@object.variant.product.taxons.present? && !@object.variant.product.taxons.include?(Spree::Taxon.find_by(permalink: 'shortvideo'))
                attach_short_video = Spree::Taxon.find_by(permalink: 'quickshout')
                @object.variant.product.taxons << attach_short_video
              end
            else
              if !@object.variant.product.taxons.present? && !@object.variant.product.taxons.include?(Spree::Taxon.find_by(permalink: 'shortvideo'))
                attach_short_video = Spree::Taxon.find_by(permalink: 'shoutout')
                @object.variant.product.taxons << attach_short_video
              end
            end
            flash[:success] = flash_message_for(@object, :successfully_created)
            respond_with(@object) do |format|
              format.html { redirect_to location_after_save }
              format.js   { render layout: false }
            end
          else
            invoke_callbacks(:create, :fails)
            respond_with(@object) do |format|
              format.html { render action: :new }
              format.js { render layout: false }
            end
          end
        else
          invoke_callbacks(:create, :fails)
          flash[:error] = @object.errors.full_messages.join(", ")
          redirect_to location_after_save
        end
      end

      def load_resource
        if member_action?
          @object ||= load_resource_instance

          # call authorize! a third time (called twice already in Admin::BaseController)
          # this time we pass the actual instance so fine-grained abilities can control
          # access to individual records, not just entire models.
          # authorize! action, @object

          instance_variable_set("@#{resource.object_name}", @object)
        else
          @collection ||= collection

          # note: we don't call authorize here as the collection method should use
          # CanCan's accessible_by method to restrict the actual records returned

          instance_variable_set("@#{controller_name}", @collection)
        end
      end

      protected
      def authorize_admin
        record = if respond_to?(:model_class, true) && model_class
                   model_class
                 else
                   controller_name.to_sym
                 end
      end
      def location_after_save
        spree.admin_product_digitals_path(@product)
      end

      def permitted_resource_params
        params.require(:digital).permit(permitted_digital_attributes)
      end

      def permitted_digital_attributes
        [:variant_id, :attachment, :attachment_file_name, :attachment_content_type]
      end

      def add_additional_paramas
        hash = {}
        hash[:attachment_file_name] = params[:digital][:attachment].original_filename
        hash[:attachment_content_type] = params[:digital][:attachment].content_type
        hash
      end
    end
  end
end
