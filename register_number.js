// base code found in AWS tutorial - https://docs.aws.amazon.com/pinpoint/latest/userguide/tutorials-two-way-sms-part-3.html
const { PinpointClient, PhoneNumberValidateCommand, UpdateEndpointCommand, SendMessagesCommand } = require("@aws-sdk/client-pinpoint"); // ES Modules import
// const pinClient = new PinpointClient({ region: process.env.region });

function getParamValue(params, paramName, isRequired, errorCallback) {
    var paramValue = null;
    if (params && Object.keys(params).length > 0) {
        paramValue = params[paramName];
    }
    if (paramValue) {
        return paramValue;
    } else {
        if (isRequired) {
            errorCallback(new Error("Value for <" + paramName + "> not provided"), 400);
        } else {
            return null;
        }
    }
}

exports.handler = async function (event, context, callback) {
    const errorCallback = (err, code) => callback(JSON.stringify({
        errorCode: code ? code : 400,
        errorMessage: err ? err.message : err
    }));

    try {
        const successCallback = (results) => callback(null,
            {
                isBase64Encoded: true,
                statusCode: 200,
                body: JSON.stringify(results),
                headers: {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
                    'Access-Control-Allow-Methods': 'GET,OPTIONS,POST,PUT',
                    'Access-Control-Allow-Origin': '*',
                    'Access-Control-Max-Age': '3600'
                }
            });

        var httpMethod = getParamValue(event, "httpMethod", true, errorCallback);
        if (httpMethod == "ERROR-BODY") {
            errorCallback(new Error("Request body is not a valid JSON"), 400);
        }
        var payload = getParamValue(event, "body", true, errorCallback);

        // get values from payload
        var destinationNumber = getParamValue(payload, "destinationNumber", true, errorCallback);
        var firstName = getParamValue(payload, "firstName", true, errorCallback);
        var lastName = getParamValue(payload, "lastName", true, errorCallback);
        var source = getParamValue(payload, "source", true, errorCallback);

        // The FromAddress must be verified in SES.
        // Make sure the SMS channel is enabled for the projectId that you specify.
        // See: https://docs.aws.amazon.com/pinpoint/latest/userguide/channels-sms-setup.html
        const projectId = process.env.PINPOINT_APP_ID;

        // You need a dedicated long code in order to use two-way SMS. 
        // See: https://docs.aws.amazon.com/pinpoint/latest/userguide/channels-voice-manage.html#channels-voice-manage-request-phone-numbers
        var originationNumber = process.env.ORIGINATION_NUMBER;

        // get values from payload
        // var payload = getParamValue(event, "body", true, errorCallback);
        // var toAddress = getParamValue(payload, "recipient", true, errorCallback);
        // var subject = getParamValue(payload, "subject", true, errorCallback);
        // var body = getParamValue(payload, "body", true, errorCallback);

        // This message is spread across multiple lines for improved readability.
        var message = "ExampleCorp: Reply YES to confirm your subscription. 2 msgs per "
            + "month. No purchase req'd. Msg&data rates may apply. Terms: "
            + "example.com/terms-sms";

        var messageType = "TRANSACTIONAL";

        const pinClient = new PinpointClient({ region: process.env.CURRENT_REGION });

        console.log('Received event:', event);
        const res = await validateNumber(errorCallback, pinClient, destinationNumber, firstName, lastName, source);
        successCallback(res);
    } catch (err) {
        errorCallback(err, 500);
    }
};

async function validateNumber(errorCallback, pinClient, destinationNumber, firstName, lastName, source) {
    var destinationNumber = destinationNumber;
    if (destinationNumber.length == 10) {
        destinationNumber = "+1" + destinationNumber;
    }
    var params = {
        NumberValidateRequest: {
            IsoCountryCode: 'US',
            PhoneNumber: destinationNumber
        }
    };
    try {
        const PhoneNumberValidateresponse = await pinClient.send(new PhoneNumberValidateCommand(params));
        console.log(PhoneNumberValidateresponse);
        if (PhoneNumberValidateresponse['NumberValidateResponse']['PhoneTypeCode'] == 0) {
            await createEndpoint(errorCallback, PhoneNumberValidateresponse, firstName, lastName, source);

        } else {
            console.log("Received a phone number that isn't capable of receiving "
                + "SMS messages. No endpoint created.");
        }
    } catch (err) {
        errorCallback(err, 500);
    }
}

async function createEndpoint(errorCallback, pinClient, data, firstName, lastName, source) {
    var destinationNumber = data['NumberValidateResponse']['CleansedPhoneNumberE164'];
    var endpointId = data['NumberValidateResponse']['CleansedPhoneNumberE164'].substring(1);

    var params = {
        ApplicationId: projectId,
        // The Endpoint ID is equal to the cleansed phone number minus the leading
        // plus sign. This makes it easier to easily update the endpoint later.
        EndpointId: endpointId,
        EndpointRequest: {
            ChannelType: 'SMS',
            Address: destinationNumber,
            // OptOut is set to ALL (that is, endpoint is opted out of all messages)
            // because the recipient hasn't confirmed their subscription at this
            // point. When they confirm, a different Lambda function changes this 
            // value to NONE (not opted out).
            OptOut: 'ALL',
            Location: {
                PostalCode: data['NumberValidateResponse']['ZipCode'],
                City: data['NumberValidateResponse']['City'],
                Country: data['NumberValidateResponse']['CountryCodeIso2'],
            },
            Demographic: {
                Timezone: data['NumberValidateResponse']['Timezone']
            },
            Attributes: {
                Source: [
                    source
                ]
            },
            User: {
                UserAttributes: {
                    FirstName: [
                        firstName
                    ],
                    LastName: [
                        lastName
                    ]
                }
            }
        }
    };
    try {
        const UpdateEndpointresponse = await pinClient.send(new UpdateEndpointCommand(params));
        console.log(UpdateEndpointresponse);
        await sendConfirmation(errorCallback, destinationNumber);
    } catch (err) {
        errorCallback(err, 500);
    }
}

async function sendConfirmation(errorCallback, pinClient, destinationNumber) {
    var params = {
        ApplicationId: projectId,
        MessageRequest: {
            Addresses: {
                [destinationNumber]: {
                    ChannelType: 'SMS'
                }
            },
            MessageConfiguration: {
                SMSMessage: {
                    Body: message,
                    MessageType: messageType,
                    OriginationNumber: originationNumber
                }
            }
        }
    };
    try {
        const SendMessagesCommandresponse = await pinClient.send(new SendMessagesCommand(params));
        console.log("Message sent! "
            + SendMessagesCommandresponse['MessageResponse']['Result'][destinationNumber]['StatusMessage']);
    } catch (err) {
        errorCallback(err, 500);
    }
}