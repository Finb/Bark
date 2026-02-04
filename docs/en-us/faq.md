### Unable to Receive Push Notifications
Check whether the Device Token is valid in the app settings. 
If it’s valid, try rebooting your device. If you still can’t receive notifications, check whether the push request returned HTTP 200.  

### DeviceToken Shows “Unknown”
This usually means the device cannot connect to Apple’s servers. You may also notice iMessage not working or other apps not receiving notifications.  
Try switching networks, rebooting the device, or disabling any proxy/VPN affecting Apple services.  
This is a connectivity issue between your device and Apple’s servers, and cannot be fixed by the app author.

### Push Usage Limit
Normal usage is not restricted. <b>Abnormal usage may result in the IP being banned for 24 hours.</b>
If more than 1,000 TCP connections are established at the same time, new requests will be rejected. When sending a large number of push notifications, please use HTTP/2 to multiplex TCP connections.

Ban rules:
1. More than 1,000 erroneous requests within 5 minutes (HTTP status codes such as 400, 404, 500, etc.).
2. More than 5 HTTP 405 error requests within 5 minutes
3. More than 5 erroneous requests within 5 minutes, with the User-Agent being “*Mozilla/5.0 (X11; Linux x86_64)”

### Receiving Unknown or Unexpected Pushes (e.g., “NoContent”)
Possible causes:  
1. Safari may auto-complete the Bark API URL when typing in the address bar and trigger preloading.  
2. Chat apps like WeChat may periodically access a Bark API URL you sent earlier.  
3. Your push key was leaked — reset it in the server list page.

### “Server Error” Prompt
Occasional errors may be ignored. The app might have gone into background causing network timeouts.

### Time-Sensitive Notifications Not Working
Try **rebooting your device**.

### Unable to Save Notification History or No Copy Button When Pulling Down Notification
Try **rebooting your device**.  
The Notification Service Extension may have failed to run, so the saving logic didn’t execute.

### Multiple Devices Using the Same Key but Only One Receives Notifications
A key can only be used by one device. Only the most recently opened app instance will receive notifications.

### Auto-Copy Not Working
On iOS 14.5+, stricter permissions prevent auto-copy when receiving notifications.  
You can instead pull down the notification or swipe left on the lock screen to trigger auto-copy, or tap the copy button.

### Defaulting to Notification History on App Launch
The app reopens to the last viewed page.  
If you exit the app on the history page, reopening it will return to the history page.

### Does the Push API Support POST Requests?
Bark supports both GET and POST, as well as JSON format.  
Parameters are the same for all request types. See the tutorial for details.

### Push Fails Due to Special Characters (e.g., links, “+” becomes space)
This happens when the URL is not properly encoded.

```sh
# Example
https://api.day.app/key/{content}

# If {content} is:
"a/b/c/"

# Final URL becomes:
https://api.day.app/key/a/b/c/
# -> No route matches, backend returns 404

# Correct (URL-encoded):
https://api.day.app/key/a%2Fb%2Fc%2F
```
HTTP libraries usually encode parameters automatically.
If constructing URLs manually, always encode parameters.

#### How to ensure privacy and security
See the [Privac](/en-us/privacy)