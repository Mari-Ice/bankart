


komentarji:

mogoce se bo dalo cist ok zintegrirat zadeve zdraven. Zgleda kot da ApplePay in GooglePay vrnejo token, ki ga lahko uporabis za placilo. Po potrebi je za to edino dodati se kake lepotne dodatke, da te service spusti cez...
https://pub.dev/packages/pay morda zadostna rešitev za to




## BANKART GATEWAY TODO:

[ ] APPLEPAY - the Gateway has to be configured with your Payment Processing certificate first.
[ ] GOOGLEPAY - account on GooglePay&Wallet Console -> MerchantID
[ ] 




# mytodo: 
--- zaenkrat vidimo da ne delaaaa ker ma gateway disablean googlepay in applepay, ga pa zazna kot moznost placila

[ ] ADD THE RESULT TOKEN FROM APPLEPAY TO THE TOKENIZER IXOPAY
<transactionToken>
applepay:{"token":{"paymentData":{"version":"EC_v1","data":"...","signature":"...","publicKeyHash":"...","transactionId":"...."}},"paymentMethod":{"displayName":"Some card","network":"MasterCard","type":"debit"},"transactionIdentifier":"..."}}
</transactionToken>

[ ] ADD THE RESULT TOKEN FROM GOOGLEPAY TO THE TOKENIZER IXOPAY
<transactionToken>
googlepay:{"signature":"...","intermediateSigningKey":{"signedKey":"{\"keyValue\":\"...\",\"keyExpiration\":\"...\"}","signatures":["..."]},"protocolVersion":"ECv2","signedMessage":"{\"encryptedMessage\":\"...\",\"ephemeralPublicKey\":\"...\",\"tag\":\"...\"}"}
</transactionToken>

[ ] prepare gateway debit/preauthorize request with TransactionToken parameter as stated


# Usage

- init the instance of Bankart object with required parameters SharedSecret, BankartStyle.
- render the object directly in the widget tree
- also possible to use bankart.client.tokenize(CardData cardData) method to tokenize the card data directly without of usage of our widget