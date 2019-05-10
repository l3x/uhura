require "administrate/base_dashboard"

class MessageDashboard < Administrate::BaseDashboard
  # ATTRIBUTE_TYPES
  # a hash that describes the type of each of the model's fields.
  #
  # Each different type represents an Administrate::Field object,
  # which determines how the attribute is displayed
  # on pages throughout the dashboard.
  ATTRIBUTE_TYPES = {
    sendgrid_msg: Field::BelongsTo,
    clearstream_msg: Field::BelongsTo,
    manager: Field::BelongsTo,
    user: Field::BelongsTo,
    team: Field::BelongsTo,
    template: Field::BelongsTo,
    id: Field::Number,
    email_subject: Field::String,
    email_message: Field::Text,
    sms_message: Field::Text,
    created_at: Field::DateTime,
    updated_at: Field::DateTime,
  }.freeze

  # COLLECTION_ATTRIBUTES
  # an array of attributes that will be displayed on the model's index page.
  #
  # By default, it's limited to four items to reduce clutter on index pages.
  # Feel free to add, remove, or rearrange items.
  COLLECTION_ATTRIBUTES = [
    :sendgrid_msg,
    :clearstream_msg,
    :manager,
    :user,
  ].freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = [
    :sendgrid_msg,
    :clearstream_msg,
    :manager,
    :user,
    :team,
    :template,
    :id,
    :email_subject,
    :email_message,
    :sms_message,
    :created_at,
    :updated_at,
  ].freeze

  # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
  FORM_ATTRIBUTES = [
    :sendgrid_msg,
    :clearstream_msg,
    :manager,
    :user,
    :team,
    :template,
    :email_subject,
    :email_message,
    :sms_message,
  ].freeze

  # Overwrite this method to customize how messages are displayed
  # across all pages of the admin dashboard.
  #
  # def display_resource(message)
  #   "Message ##{message.id}"
  # end
end