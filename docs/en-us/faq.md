#### Push usage limit <!-- {docsify-ignore-all} -->
Normal requests (HTTP status code 200) have no limit.<br>
But if more than 1000 error requests (HTTP status code 400 404 500) are made within 5 minutes, <b>the IP will be BAN for 24 hours</b> 

#### Time-sensitive notifications not work
You can try to <b>restart your device</b> to solve it.

#### Unable to save notification history, or unable to copy by pulling down push or swiping left on lock screen without clicking copy button
You can try to <b>restart your device</b> to solve it.<br />
Due to some reasons, the push service extension （[UNNotificationServiceExtension](https://developer.apple.com/documentation/usernotifications/unnotificationserviceextension)） failed to run normally, and the code for saving notifications was not executed properly.

#### Automatic copy push failure 
After iOS 14.5 version, due to permission tightening, it is not possible to automatically copy push content to clipboard when receiving push. <br/>
You can temporarily pull down push or swipe left on lock screen and click view to automatically copy, or click copy button on pop-up push.

#### Open notification history page by default
When you open APP again, it will jump to the last opened page.<br />
Just exit APP when you are on history message page. When you open APP again, it will be history message page.

#### Does push API support POST request?
Bark supports GET POST , supports using Json <br>
No matter which request method, parameter names are the same. Refer to [usage tutorial](/en-us/tutorial)

#### Pushing special characters causes push failure. For example: Push content contains link or Push abnormal such as + becomes space 
This is because of the problem of irregular link. It often happens<br>
When splicing URL, pay attention to URL encoding parameters

```sh
# For example
https://api.day.app/key/{push content}

# If {push content} is
"a/b/c/"

# Then the final spliced URL is
https://api.day.app/key/a/b/c/
# The corresponding route will not be found and the backend program will return 404

#You should url encode {push content} before splicing
https://api.day.app/key/a%2Fb%2Fc%2F
```
 If you use a mature HTTP library, parameters will be automatically processed and you don’t need manual encoding. <br>
But if you splice URL yourself, you need special attention for special characters in parameters. **It’s better not care whether there are special characters or not and blindly apply a layer of URL encoding.**

#### How to ensure privacy and security
Refer [privacy security](/en-us/privacy)
