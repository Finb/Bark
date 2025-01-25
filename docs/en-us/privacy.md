#### How Privacy Can Be Leaked <!-- {docsify-ignore-all} -->
The route a push notification takes from sending to receiving is as follows:<br>
Sender <font color='red'> → Server①</font> → Apple APNS Server → Your Device → <font color='red'>Bark APP②</font>.

The two red-marked areas are potential points of privacy leakage <br>
* The sender does not use HTTPS or uses a public server*（the author can see the request logs）*
* The Bark App itself is insecure, and the version uploaded to the App Store has been modified.

#### Solving Server-Side Privacy Issues
* You can use the open-source backend code to [ deploy your own backend service ](/en-us/deploy.md) and enable HTTPS.
* Use [encrypted push](/en-us/encryption) with a custom key to encrypt the push content.

#### Ensuring the App is Completely Built from Open-Source Code
To ensure that the App is secure and has not been modified by anyone (including the author), Bark is built by GitHub Actions and then uploaded to the App Store.<br>
Within the Bark app settings, you can view the GitHub Run Id. Clicking on it will allow you to find the configuration files used for the current version's build, the source code at compile time, the build number of the version uploaded to the App Store, and more.<br>


The same build number can only be uploaded to the App Store once, making this number unique.<br>
You can use this number to compare with the Bark App downloaded from the store. If they match, it proves that the App downloaded from the App Store is completely built from open-source code.

Example: Bark 1.2.9 - 3 <br> 
https://github.com/Finb/Bark/actions/runs/3327969456

1. Find the commit id at compile time to view the complete source code at compile time.
2. Check .github/workflows/testflight.yaml to verify all Actions and ensure that the logs printed by the Actions have not been tampered with.
3. View Action Logs https://github.com/Finb/Bark/actions/runs/3327969456/jobs/5503414528
4. Find the packaged App ID, Team ID, version, and build number uploaded to the App Store, among other information.
5. Download the corresponding version ipa from the store and compare whether the build number matches the one in the logs*（this number is unique for the same APP, and once successfully uploaded, it cannot be uploaded again with the same version build number）*


*Here, we do not consider whether iOS leaks privacy.*