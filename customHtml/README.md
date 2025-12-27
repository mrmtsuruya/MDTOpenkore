# HTML Customizing Portal Page

To ensure proper system functionality, only modify the specified files. Changing other files may impact the overall performance.

## loadConfig.json
This file includes the basic configuration for authentication page. Key settings include:

* post_url: Indicates the URL for redirecting after a successful login (max 512 bytes).
* oneclick_validity: Limits the duration of network access for one-click authentication (range: 0–720 minutes; 0 means no limit).
* oneclick_times: Sets the daily login limit for one-click authentication (range: 0–10; 0 means no limit).
* up_rate & down_rate: Indicates the maximum uplink and downlink bandwidth settings (range: 0–1000 Mbps; 0 means no limit).
* login_options: Determines the authentication type, such as:
* voucher for voucher-based authentication,
* fixaccount for account-based authentication,
* pass for one-click authentication.
* lang: Specifies the supported languages. Additional languages can be added by updating the corresponding text content in the 
language.js file.
css/index.css
Controls the look and layout of the authentication page. You can modify colors, fonts, and other layout elements to customize the appearance.

## js/language.js
Manages the text displayed on the interface and supports multilingual configurations. To add a new language, include the corresponding text content in this file.

## js/index.js
Handles the page's logic and interactive functions.
