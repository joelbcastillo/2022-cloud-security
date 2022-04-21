from flask import Flask, request

app = Flask(__name__)

import dynamodb_handler as dynamodb


@app.route('/')
def root_route():
    dynamodb.CreateDataRecorder()
    return 'Hello World'

#  Route: http://localhost:5000/entry
#  Method : POST
@app.route('/entry', methods=['POST'])
def add_entry():

    data = request.get_json()
    # id, ... = 1001, ...

    response = dynamodb.addItemToBook(data['id'], data['title'], data['author'])    
    
    if (response['ResponseMetadata']['HTTPStatusCode'] == 200):
        return {
            'msg': 'Added successfully',
        }

    return {  
        'msg': 'Some error occcured',
        'response': response
    }


#  Route: http://localhost:5000/entry/<id>
#  Method : GET
@app.route('/book/<int:id>', methods=['GET'])
def getBook(id):
    response = dynamodb.GetItemFromBook(id)
    
    if (response['ResponseMetadata']['HTTPStatusCode'] == 200):
        
        if ('Item' in response):
            return { 'Item': response['Item'] }

        return { 'msg' : 'Item not found!' }

    return {
        'msg': 'Some error occured',
        'response': response
    }

if __name__ == '__main__':
    app.run(host='127.0.0.1', port=5000, debug=True)
