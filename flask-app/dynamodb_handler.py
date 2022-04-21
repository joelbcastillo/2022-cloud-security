# import boto3
from boto3 import client, resource
import os

AWS_ACCESS_KEY_ID     = os.environ.get("AWS_ACCESS_KEY_ID")
AWS_SECRET_ACCESS_KEY = os.environ.get("AWS_SECRET_ACCESS_KEY")
REGION_NAME           = os.environ.get("REGION_NAME")
# AWS_SESSION_TOKEN     = os.environ.get("AWS_SESSION_TOKEN")

client = client(
    'dynamodb',
    aws_access_key_id     = AWS_ACCESS_KEY_ID,
    aws_secret_access_key = AWS_SECRET_ACCESS_KEY,
    region_name           = REGION_NAME,
    # aws_session_token     = AWS_SESSION_TOKEN,
)

resource = resource(
    'dynamodb',
    aws_access_key_id     = AWS_ACCESS_KEY_ID,
    aws_secret_access_key = AWS_SECRET_ACCESS_KEY,
    region_name           = REGION_NAME,
    # aws_session_token     = AWS_SESSION_TOKEN,
)
# BookTable = DynamoDB.Table('Book')

'''
    https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/dynamodb.html#DynamoDB.Client.create_table
    Create a new table
'''
def create_table(table_name):
        
    client.create_table(
        AttributeDefinitions = [ #array of attributes (name and type)
            {
                'AttributeName': 'id', # Name of the attribute
                'AttributeType': 'N'   # N -> Number (S -> String, B-> Binary)
            }
        ],
        TableName = table_name, # Name of the table 
        KeySchema = [       # 
            {
                'AttributeName': 'id',
                'KeyType'      : 'HASH' # HASH -> partition key, RANGE -> sort key
            }
        ],
        BillingMode = 'PAY_PER_REQUEST',
        Tags = [ # OPTIONAL 
            {
                'Key' : 'Name',
                'Value': 'dynamodb-data-historian'

            }
        ]
    )

'''
    https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/GettingStarted.Python.03.html
    CRUD Operations
'''

def add_item(table_name, id):
    table = resource.Table(table_name)

    response = table.put_item(
        Item = {
            'id'     : id,
        }
    )

    return response

def get_item(table_name, id):
    table = resource.Table(table_name)

    response = table.get_item(
        Key = {
            'id'     : id
        },
        AttributesToGet=[
        ]
    )

    return response
