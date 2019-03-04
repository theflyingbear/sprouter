# a few scripts to interact with Telegram and/or Twilio

* [tg-icinga2](tg-icinga2.sh) - notification script for Icinga2 and Telegram
  example config: (put the numerical Telegram user/chat ID in `$user.email$`):
  
```
object NotificationCommand "telegram-host-notification" {
  command = [ ConfigDir + "/scripts/tg-icinga2.sh" ]

  arguments += {
    "-x" = "host"
    "-4" = "$address$"
    "-6" = "$address6$"
    "-b" = "$notification.author$"
    "-c" = "$notification.comment$"
    "-d" = "$icinga.long_date_time$"
    "-f" = "$notification_from$"
    "-i" = "$notification_icingaweb2url$"
    "-l" = "$host.name$"
    "-n" = "$host.display_name$"
    "-o" = "$host.output$"
    "-r" = "$user.email$"
    "-s" = "$host.state$"
    "-t" = "$notification.type$"
  }
}

object NotificationCommand "telegram-service-notification" {
  command = [ ConfigDir + "/scripts/tg-icinga2.sh" ]

  arguments += {
    "-x" = "service"
    "-4" = "$address$"
    "-6" = "$address6$"
    "-b" = "$notification.author$"
    "-c" = "$notification.comment$"
    "-d" = "$icinga.long_date_time$"
    "-e" = "$service.name$"
    "-f" = "$notification_from$"
    "-i" = "$notification_icingaweb2url$"
    "-l" = "$host.name$"
    "-n" = "$host.display_name$"
    "-o" = "$service.output$"
    "-r" = "$user.email$" 
    "-s" = "$service.state$"
    "-t" = "$notification.type$"
    "-u" = "$service.display_name$"
  }
}

apply Notification "telegram-notif" to Host {
  import "telegram-host-notification"
  user_groups = host.vars.notification.TG.groups
  users = host.vars.notification.TG.users

   if (host.vars.notification_repeat) {
    interval = host.vars.notification_repeat
  } else {
    interval = 2h
  }

  if (host.vars.notification_period) {
    period = host.vars.notification_period
  } else {
    period = "24x7"
  }

  assign where host.vars.notification_type == "telegram"
}

apply Notification "telegram-notif" to Service {
  import "telegram-service-notification"
  user_groups = host.vars.notification.TG.groups
  users = host.vars.notification.TG.users

  if (service.vars.notification_repeat) {
    interval = service.vars.notification_repeat
  } else {
    interval = 2h
  }

  if (service.vars.notification_period) {
    period = service.vars.notification_period
  } else {
    period = "24x7"
  }

  assign where host.vars.notification_type == "telegram"
}

template Notification "telegram-host-notification" {
  command = "telegram-host-notification"

  states = [ Up, Down ]
  types = [ Problem, Acknowledgement, Recovery, Custom,
            FlappingStart, FlappingEnd,
            DowntimeStart, DowntimeEnd, DowntimeRemoved ]

  vars += {
    notification_icingaweb2url = "https://.../icingaweb2"
    notification_from = "Sup <noreply@...>"
    notification_logtosyslog = false
  }

  period = "24x7"
}

template Notification "telegram-service-notification" {
  command = "telegram-service-notification"

  states = [ OK, Warning, Critical, Unknown ]
  types = [ Problem, Acknowledgement, Recovery, Custom,
            FlappingStart, FlappingEnd,
            DowntimeStart, DowntimeEnd, DowntimeRemoved ]

  vars += {
    notification_icingaweb2url = "https://.../icingaweb2"
    notification_from = "Sup <noreply@...>"
    notification_logtosyslog = false
  }

  period = "24x7"
}

object Host  example" {
 import "generic-hsot"
 ...
  vars.notification["TG"] = {
    groups = [ "icingaadmins" ]
  }
  vars.notification_type = "telegram" 
}
```

* [tg-nagios](tg-nagios.sh) - notification script for Nagios3 and Telegram
  Example configuration - put the numerical Telegram user/chat ID in the contact's pager 

```
define command {
    command_name notify-host-telegram
    command_line /usr/local/bin/tg-nagios.sh host undef $CONTACTPAGER$ "$HOSTNAME$" "$HOSTADDRESS$" "$HOSTOUTPUT$"
}

define command {
    command_name notify-svc-telegram
    command_line /usr/local/bin/tg-nagios.sh service undef $CONTACTPAGER$ "$SERVICEDESC$" "$HOSTNAME$" "$SERVICEOUTPUT$"
}

define contact {
    contact_name    Telegram User
    alias           telegram-user
    service_notification_period 24x7
    host_notification_period 24x7
    service_notification_options w,c,r
    host_notification_options d,r
    service_notification_commands notify-svc-telegram
    host_notification_commands notify-host-telegram
    pager 1234567890 
}
...
```

* [Twilio](twilio/) - scripts to use with a Twilio phone number

