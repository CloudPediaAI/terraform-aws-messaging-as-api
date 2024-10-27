// Import required AWS SDK clients and commands for Pinpoint functionalities
const { PinpointClient, SendMessagesCommand } = require("@aws-sdk/client-pinpoint");

async function sendEmail(toAddress, params, errorCallback) {
  const pinClient = new PinpointClient({ region: process.env.CURRENT_REGION });

  const { MessageResponse } = await pinClient.send(
    new SendMessagesCommand(params),
  );

  if (!MessageResponse) {
    errorCallback(new Error("No message response."), 500);
  }

  if (!MessageResponse.Result) {
    errorCallback(new Error("No message result."), 500);
  }

  const recipientResult = MessageResponse.Result[toAddress];

  if (recipientResult.StatusCode !== 200) {
    errorCallback(new Error(recipientResult.StatusMessage), 400);
  } else {
    return recipientResult;
  }
}

function getParamValue(params, paramName, isRequired, errorCallback) {
  var paramValue = null;
  if (params) {
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

function getParamValueNumeric(params, paramName, isRequired, errorCallback) {
  var paramValue = null;
  if (params) {
    paramValue = params[paramName];
  }
  if (typeof paramValue != "number") {
    if (isRequired) {
      errorCallback(new Error("Value for <" + paramName + "> not provided"), 400);
    } else {
      return null;
    }
  } else {
    return paramValue;
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

    // The FromAddress must be verified in SES.
    const projectId = process.env.PINPOINT_APP_ID;
    const fromAddress = process.env.FROM_EMAIL_ID;

    var httpMethod = getParamValue(event, "httpMethod", true, errorCallback);
    if (httpMethod == "ERROR-BODY") {
      errorCallback(new Error("Request body is not a valid JSON"), 400);
    }
    var payload = getParamValue(event, "body", true, errorCallback);

    // get values from payload
    var toAddress = getParamValue(payload, "recipient", true, errorCallback);
    var subject = getParamValue(payload, "subject", true, errorCallback);
    var body = getParamValue(payload, "body", true, errorCallback);

    // The character encoding for the subject line and message body of the email.
    var charset = "UTF-8";

    const params = {
      ApplicationId: projectId,
      MessageRequest: {
        Addresses: {
          [toAddress]: {
            ChannelType: "EMAIL",
          },
        },
        MessageConfiguration: {
          EmailMessage: {
            FromAddress: fromAddress,
            SimpleEmail: {
              Subject: {
                Charset: charset,
                Data: subject,
              },
              HtmlPart: {
                Charset: charset,
                Data: body,
              },
              TextPart: {
                Charset: charset,
                Data: body,
              },
            },
          },
        },
      },
    };

    const res = await sendEmail(toAddress, params, errorCallback);
    successCallback(res);
  } catch (err) {
    errorCallback(err, 500);
  }
};
