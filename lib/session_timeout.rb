module SessionTimeout
  def self.included(base)
    base.extend(ClassMethods)
  end
  
  module ClassMethods
    def session_times_out_in(time, opts={})
      opts[:after_timeout] = opts[:after_timeout] || nil
      class_eval { prepend_before_filter Proc.new { |c| c.check_session_expiry(time, opts)}, :except => opts[:except]  }
    end
  end
  
  def check_session_expiry(time, opts)
    if session[:expires_at]
      if session_has_timed_out?
        logger.info "\033[0;31mSession has expired!\033[0m"
        reset_session
        unless opts[:after_timeout].nil?
          return opts[:after_timeout].call(self) if opts[:after_timeout].instance_of?(Proc)
          return self.send(opts[:after_timeout]) if opts[:after_timeout].instance_of?(Symbol)
        end
      else
        initialize_session_expiry(time)
      end
    else
      initialize_session_expiry(time)
    end
  end
  
  protected    
    def initialize_session_expiry(time)
      expires_at = time.from_now
      formatted_expires_at = expires_at.strftime('%T')
      logger.info "\033[0;34mSession expires at \033[0;1m#{formatted_expires_at}\033[0m"
      session[:expires_at] = expires_at
    end
    
    def session_has_timed_out?
      Time.now > session[:expires_at]
    end
end