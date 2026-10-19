# Data safety form answers

Play Console > App content > Data safety. These answers are based on the release build: no INTERNET permission, no network code, no analytics or ads SDKs, and only `shared_preferences` and `audioplayers` as plugins.

## Data collection and security

| Question | Answer |
|---|---|
| Does your app collect or share any of the required user data types? | **No** |

Choosing "No" skips the rest of the form. Google's definition of "collect" means transmitting data off the device. Data kept only on-device, such as settings and session history, is not collected.

Google's guidance also says data backed up through Android's own Auto Backup is not counted as collection by the developer.

## Resulting store label

"No data collected" and "No data shared with third parties".

## Re-check this form if you ever add

- Firebase, Crashlytics, Sentry or any analytics or crash reporting.
- Ads.
- Cloud sync or accounts.
- Any HTTP calls.
