class Service::Sms < Service::Base
  title 'SMS'

  def self.label_impact_level(level)
    "Impact Level #{level} Recipients"      
  end

  string :level_1_recipients,
    :placeholder => '888.867.5309',
    :label => "Send SMS Notifications to your phone<br /><br />" \
      "#{label_impact_level(1)}"
  
  string :level_2_recipients,
    :placeholder => '888.867.5309',
    :label => label_impact_level(2)

  string :level_3_recipients,
    :placeholder => '888.867.5309',
    :label => label_impact_level(3)
  
  string :level_4_recipients,
    :placeholder => '888.867.5309',
    :label => label_impact_level(4)

  string :level_5_recipients,
    :placeholder => '888.867.5309',
    :label => label_impact_level(5)


  page 'SMS service hook', 
    [:level_1_recipients, 
    :level_2_recipients, 
    :level_3_recipients,
    :level_4_recipients,
    :level_5_recipients]

  def receive_issue_impact_change(config, issue)

    impact_level = issue[:event_data][:new_impact]
    impacted_devices_count = issue[:impacted_devices_count]
    recipients = config["level_#{impact_level}_recipients"]
    log_issue_impact_change(recipients, impact_level,  impacted_devices_count, issue)
    log("found issue #{issue}")
    :no_resource
  end

  def receive_verification(config, _)
    #payload = JSON.generate(:event => 'verification')
    [true, 'Verification successfully completed (NOOP)']
  end
  

  private
  
  def log_issue_impact_change(recipients, impact_level, impacted_devices_count, issue)
    log("ALERT, TO: #{recipients}, MSG: Alert: You have a level #{impact_level} issue effecting #{impacted_devices_count} Devices. Visit your Crashlytics Dashboard to learn more")
  end
end
