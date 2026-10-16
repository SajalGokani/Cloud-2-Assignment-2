import json
import os

def handler(event, context):
    try:
        if os.path.exists('tl_sample_coupons_list_response.json'):
            with open('tl_sample_coupons_list_response.json', 'r') as f:
                body_data = json.load(f)
        else:
            body_data = {
                "coupons": [
                    {"id": "CUP001", "code": "SUMMER20", "discount": "20%", "description": "20% off summer collection"},
                    {"id": "CUP002", "code": "WELCOME10", "discount": "10%", "description": "10% off first order"}
                ]
            }
    except Exception as e:
        body_data = {"error": str(e)}

    return {
        "statusCode": 200,
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*"
        },
        "body": json.dumps(body_data)
    }
