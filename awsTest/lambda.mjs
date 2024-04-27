import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocumentClient, PutCommand } from "@aws-sdk/lib-dynamodb";
import { randomUUID } from "crypto";

const ddbDocClient = DynamoDBDocumentClient.from(new DynamoDBClient({region: "eu-central-1"}))

export const handler = async (event,context) => {
  try{

    const fileReceived = JSON.parse(event.body);

    const newFile = {
      ...fileReceived,
      id: randomUUID(),
    };

    await ddbDocClient.send(new PutCommand({
      TableName: "files",
      Item: newFile,
    }));

    return {
      statusCode: 201,
      body: JSON.stringify(newFile),
    };

  }catch(error){
    console.error(error)
    return {
      statusCode: 500,
      body: JSON.stringify({message: error.message})
    }
  }
}