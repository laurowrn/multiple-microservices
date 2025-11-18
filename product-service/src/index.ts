import express, { Request, Response } from "express";
import morgan from "morgan";

const app = express();
const port = "3000";

type Product = {
    id: number,
    name: string,
    price: number
    quantity: number
}

const products: Product[] = []

app.use(express.json())
app.use(morgan('dev'))

app.post("/product", (req: Request, res: Response) => {
    const productName: string = req.body.name
    const productPrice: number = Number(req.body.price)
    const productQuantity: number = Number(req.body.quantity)
    products.push({ id: products.length, name: productName, price: productPrice, quantity: productQuantity })
    res.status(200).json({ id: products.length - 1 })
})

app.get("/product/:productId", (req: Request, res: Response) => {
    const productId: number = Number(req.params.productId)
    const product: Product | undefined = products.find((product: Product) => product.id == productId)
    if (product) {
        res.status(200).json(product)
        return;
    }
    res.status(404).send("product not found")
})

app.post("/product/update_stock/:productId", (req: Request, res: Response) => {
    const productId: number = Number(req.params.productId)
    const quantity: number = Number(req.body.quantity)
    const modifiedProduct: Product | undefined = products.find((product: Product) => product.id == productId)
    if (!modifiedProduct) {
        res.status(404).send("product not found")
        return
    }
    modifiedProduct.quantity = modifiedProduct.quantity - quantity;
    products.map((product: Product, index: number) => {
        if (product.id == productId) {
            products[index] = modifiedProduct
        }
    })
    res.status(200).send("product stock updated")
})

app.get("/health", (req: Request, res: Response) => {
    res.status(200).json({ status: "ok" })
})

app.listen(port, () => {
    console.log(`Product service listening on port ${port}`);
});