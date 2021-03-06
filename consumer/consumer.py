from kafka import KafkaConsumer
from protobuf3.message import Message
from protobuf3.fields import StringField, Int32Field, MessageField
import datetime

consumer = KafkaConsumer(
    'mytopic',
    bootstrap_servers=['kafka-1:29092'])

"""schema"""
class Transaction(Message):
    transaction_id = StringField(field_number=1, required=True)
    account_number = Int32Field(field_number=2, required=True)
    transaction_reference = StringField(field_number=3, required=True)
    transaction_datetime = StringField(field_number=4, required=True)
    amount = Int32Field(field_number=5, required=True)

class Details(Message):
    data = MessageField(field_number=1, repeated=True, message_cls=Transaction)
details = Details()

total,count=0,0
border=1000
#listener
for message in consumer:
    message = message.value
    details.parse_from_bytes(message)
    for d in details.data:
        try:
            date_prod = (datetime.datetime.strptime(d.transaction_datetime,"%Y-%m-%dT%H:%M:%S.%f"))
        except:
            continue
        datetime_cons = datetime.datetime.now()
        difference = datetime_cons - date_prod
        elem = str(difference).split(':')[2]
        total = total + float(elem)
        count = count + 1
    if count==border:
        print(total/count)
        border=border*2
