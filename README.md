تمام ✅
خلينا نعدّل الـ **Dockerfile** و **docker-entrypoint.sh** بحيث:

* قاعدة بيانات SQLite تتخزن في مجلد ثابت: `/app/instance`
* هذا المجلد يُعتبر **Volume** في Docker → يعني ممكن تربطه بمجلد خارجي عند التشغيل (حتى البيانات تبقى لو الحاوية انمسحت).

---

## 🔹 Dockerfile (مُحسّن)

```dockerfile
# Use official Ubuntu as base image
FROM ubuntu:24.04

# Avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Update and install basic packages
RUN apt-get update && \
    apt-get install -y \
    curl \
    wget \
    git \
    vim \
    sudo \
    python3 \
    python3-pip \
    python3-venv \
    build-essential && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy project files
COPY . /app

# Create Python virtual environment
RUN python3 -m venv venv

# Activate venv, upgrade pip, install requirements
RUN /bin/bash -c "source venv/bin/activate && \
    pip install --upgrade pip && \
    pip install -r requirements.txt"

# Environment variable for venv
ENV VIRTUAL_ENV=/app/venv
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

# SQLite instance directory
RUN mkdir -p /app/instance
VOLUME ["/app/instance"]

# Copy entrypoint script
COPY docker-entrypoint.sh /app/docker-entrypoint.sh
RUN chmod +x /app/docker-entrypoint.sh

ENTRYPOINT ["/app/docker-entrypoint.sh"]

# Run Flask server by default
CMD ["flask", "run", "--host=0.0.0.0", "--port=5000"]
```

---

## 🔹 docker-entrypoint.sh (مُحسّن)

```bash
#!/bin/bash
set -e

echo ">>> Ensuring instance directory exists..."
mkdir -p /app/instance

echo ">>> Running Flask database migrations..."
flask db init || true
flask db migrate -m "Auto migration" || true
flask db upgrade || true

echo ">>> Creating admin user..."
flask create-admin || true

echo ">>> Starting Flask app..."
exec "$@"
```

---

## 🔹 كيفية التشغيل

### بناء الصورة:

```bash
docker build -t myflaskapp .
```

### تشغيل الحاوية في الخلفية مع Volume للبيانات:

```bash
docker run -d --name myflaskapp \
  -p 5000:5000 \
  -v $(pwd)/data:/app/instance \
  myflaskapp
```

🔹 الآن:

* قاعدة بيانات SQLite محفوظة في جهازك داخل `./data/app.db`
* حتى لو مسحت الحاوية → البيانات تبقى موجودة

---

هل تحب أضيف أيضًا **متغيرات بيئة (ENV)** في Dockerfile (مثل `FLASK_APP` و `FLASK_ENV`) بحيث تحدد التطبيق وأوضاع التشغيل (development / production) تلقائيًا؟
