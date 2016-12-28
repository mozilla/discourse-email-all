# name: email-all
# about: Allow an admin to email everybody
# version: 0.0.2
# author: Leo McArdle
# url: https://github.com/LeoMcA/discourse-email-all

enabled_site_setting :email_all_enabled

add_admin_route 'email_all.title', 'email-all'

after_initialize do
  require_dependency File.expand_path("../jobs/user_email_custom.rb", __FILE__)

  module ::EmailAll
    class Engine < ::Rails::Engine
      isolate_namespace EmailAll
    end
  end

  class EmailAll::EmailController < Admin::AdminController
    def send_email
      User.find_each(batch_size: 5000) do |user|
        Jobs.enqueue(:user_email_custom,
                     user_id: user.id,
                     type: 'email_all',
                     subject: params[:subject],
                     body: params[:body])
      end
      render nothing: true, status: 204
    end
  end

  class EmailAll::Mailer < ActionMailer::Base
    include Email::BuildEmailHelper

    def send_email(to, opts)
      build_email(to, subject: opts[:subject], body: opts[:body])
    end
  end

  EmailAll::Engine.routes.draw do
    post '/' => 'email#send_email'
  end

  Discourse::Application.routes.append do
    get '/admin/plugins/email-all' => 'admin/plugins#index', constraints: AdminConstraint.new
    mount EmailAll::Engine => 'admin/plugins/email-all', constraints: AdminConstraint.new
  end
end
