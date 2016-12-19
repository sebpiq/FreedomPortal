test scenarios
================

I. iOS
--------

### Ia. Full browser mode

Ia1. Connect to wifi, CNA opens, click on link it opens in Safari
Ia2. Connect to wifi, CNA opens, wait 3mn, click on link it opens in Safari
    This is for testing that even if we do not answer consecutive CaptiveNetworkSupport
    requests with iOS "success" page, the link will still open in Safari.


### Ib. CNA mode

Ib1. Connect to wifi, CNA opens, click on link it opens in CNA


II. Android
------------

There is no CNA in Android. 
When connecting to the wifi there should be a notification : "Wi-Fi network may require additional steps".