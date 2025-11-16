from fastapi import FastAPI, HTTPException, status
import requests
import os

app = FastAPI()
orders = []
USER_SERVICE_BASE_URL = os.getenv('USER_SERVICE_BASE_URL')
PRODUCT_SERVICE_BASE_URL = os.getenv('PRODUCT_SERVICE_BASE_URL')

def calculatePayment(products):
    sum = 0
    for product in products:
        sum = sum + product.quantity*product.price
    return sum

@app.post("/order")
def create_order(order_data: dict):
    product_quantities = order_data["product_quantities"]
    user_id = order_data["user_id"]
    order_price_sum = 0
    for product_quantity in product_quantities:
        response = requests.get(f"{PRODUCT_SERVICE_BASE_URL}/product/{product_quantity["product_id"]}")
        if response.status_code != 200:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="product not found")
        product = response.json()
        order_price_sum = product_quantity["quantity"]*product["price"]
    for product_quantity in product_quantities:
        response = requests.post(f"{PRODUCT_SERVICE_BASE_URL}/product/update_stock/{product_quantity["product_id"]}", json={"quantity": product_quantity["quantity"]})
        if response.status_code != 200:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="product not found")
    response = requests.post(f"{USER_SERVICE_BASE_URL}/user/pay", json={"user_id": user_id, "value": order_price_sum})
    if response.status_code != 200:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="user not found")
    return {"order_price_sum": order_price_sum}


@app.get("/")
def read_root():
    return {"message": "Hello"}