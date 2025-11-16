FROM python:3.12-slim AS builder

WORKDIR /app

RUN pip install --upgrade pip

COPY ./requirements.txt ./
RUN pip install --user -r requirements.txt

FROM python:3.12-slim

WORKDIR /app

COPY --from=builder /root/.local /root/.local

ENV PATH=/root/.local/bin:$PATH

COPY ./main.py .

EXPOSE 3002

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "3002"]