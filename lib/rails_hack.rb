class CGI::Session::ActiveRecordStore::Session
  def before_save()
    self.user_id = data[:user].id if (loaded? and not data[:user].nil?)
  end
end

module ActionView::Helpers::ActiveRecordHelper
  alias_method :lz_error_messages_for, :error_messages_for
  def error_messages_for(*params)
    options = params.extract_options!.symbolize_keys
    options[:header_message] = 'Following errors occured during last submit'[:active_record_error_header]
    options[:message] = ""[:active_record_error_message]
    params.push(options)
    lz_error_messages_for(*params)
  end
end