تمام ✅
إليك النسخة النهائية من الـ **Dockerfile** مع تشغيل التطبيق تلقائيًا بعد التهيئة:

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

# Copy local files to container
COPY . /app

# Create Python virtual environment
RUN python3 -m venv venv

# Activate virtual environment, upgrade pip, and install requirements
RUN /bin/bash -c "source venv/bin/activate && \
    pip install --upgrade pip && \
    pip install -r requirements.txt"

# Set environment variable to automatically activate venv
ENV VIRTUAL_ENV=/app/venv
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

# Copy entrypoint script
COPY docker-entrypoint.sh /app/docker-entrypoint.sh
RUN chmod +x /app/docker-entrypoint.sh

ENTRYPOINT ["/app/docker-entrypoint.sh"]

# Run Flask server by default
CMD ["flask", "run", "--host=0.0.0.0", "--port=5000"]
```

---

### ملف `docker-entrypoint.sh`

ضعه في نفس مجلد المشروع:

```bash
#!/bin/bash
set -e

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

🔹 النتيجة:

* عند تشغيل الحاوية (`docker run`):

  1. يعمل `flask db init/migrate/upgrade`.
  2. يتم إنشاء المستخدم admin (إذا لم يكن موجودًا).
  3. يبدأ السيرفر مباشرة على `http://localhost:5000`.

هل تريد مني أن أعدل السكربت بحيث **يتحقق أولًا إذا كان admin موجودًا** قبل محاولة إعادة إنشائه، بدل ما يستخدم `|| true`؟

تمام ✨ خليني أرتبلك هيكلية مشروعك (داخل وخارج الحاوية) بعد إضافة البيئة الافتراضية وملفات الـ Docker:

---

## 📂 هيكلية المشروع على جهازك (قبل بناء Docker)

```
your-project/
│
├── app/                      # كود التطبيق Flask
│   ├── __init__.py
│   ├── models.py
│   ├── routes.py
│   ├── forms.py
│   └── ...
│
├── migrations/               # ملفات الترحيل (flask db init ينشئها)
│   └── ...
│
├── requirements.txt          # مكتبات Python
├── docker-entrypoint.sh      # سكربت التهيئة وتشغيل السيرفر
├── Dockerfile                # ملف بناء الصورة
└── README.md
```

---

## 📂 هيكلية الملفات داخل الحاوية (بعد بناء وتشغيل Docker)

```
/app/
│
├── app/                      # نفس كود Flask المنسوخ
│   ├── __init__.py
│   ├── models.py
│   ├── routes.py
│   ├── forms.py
│   └── ...
│
├── migrations/               # تُنشأ عند أول تشغيل الحاوية
│   └── ...
│
├── venv/                     # البيئة الافتراضية (Python virtual env)
│   ├── bin/
│   ├── lib/
│   ├── include/
│   └── ...
│
├── requirements.txt
├── docker-entrypoint.sh
└── (ملفات أخرى نسختها من جهازك)
```

---

## 🔹 ملاحظات:

* كل ملفات مشروعك تُنسخ إلى `/app` داخل الحاوية بسبب `WORKDIR /app` و `COPY . /app`.
* البيئة الافتراضية موجودة داخل `/app/venv`.
* عند تشغيل الحاوية:

  * `docker-entrypoint.sh` ينفذ أوامر **تهيئة قاعدة البيانات**.
  * بعدها يبدأ السيرفر بـ `flask run --host=0.0.0.0 --port=5000`.

---

هل تحب أرتبلك هيكلية محسّنة بحيث نخلي **venv خارج مجلد الكود** (مثلاً في `/opt/venv`) علشان ما يختلط مع ملفات مشروعك؟

ممتاز 👌
خليني أشرحلك خطوة بخطوة كيف تشغّل مشروعك باستخدام الـ **Dockerfile** اللي كتبناه:

---

## 1️⃣ تجهيز المشروع

تأكد أن عندك الملفات التالية في جذر المشروع:

```
your-project/
├── app/                     # مجلد كود Flask
│   ├── __init__.py
│   └── ...
├── requirements.txt         # مكتبات Python
├── docker-entrypoint.sh     # سكربت التهيئة
├── Dockerfile               # ملف البناء
```

وتأكد أن `docker-entrypoint.sh` عنده صلاحيات تنفيذ:

```bash
chmod +x docker-entrypoint.sh
```

---

## 2️⃣ بناء الصورة (Image)

من داخل مجلد المشروع نفّذ:

```bash
docker build -t myflaskapp .
```

* `myflaskapp` هو اسم الصورة (ممكن تغيّره).
* النقطة `.` تعني "خذ الـ Dockerfile من المجلد الحالي".

---

## 3️⃣ تشغيل الحاوية (Container)

شغّل الحاوية واربط المنفذ 5000:

```bash
docker run -it --rm -p 5000:5000 myflaskapp
```

🔹 التفسير:

* `-it` يعطيك تيرمنال تفاعلي.
* `--rm` يمسح الحاوية بعد إيقافها.
* `-p 5000:5000` يربط منفذ الحاوية (5000) مع منفذ جهازك.

---

## 4️⃣ الوصول للتطبيق

بعد تشغيل الحاوية، اذهب للمتصفح وافتح:

```
http://localhost:5000
```

🚀 سترى تطبيق Flask شغال.

---

## 5️⃣ ماذا يحدث عند التشغيل؟

بفضل `docker-entrypoint.sh`:

1. ينفّذ:

   * `flask db init` (إذا ما في migrations).
   * `flask db migrate -m "Auto migration"`.
   * `flask db upgrade`.
   * `flask create-admin`.
2. بعدها يبدأ السيرفر:

   ```
   flask run --host=0.0.0.0 --port=5000
   ```

---

هل تحب أكتبلك أيضًا أوامر **تشغيل مع قاعدة بيانات خارجية (مثل MySQL/Postgres) باستخدام متغيرات بيئة في Docker** بدل SQLite الافتراضي؟

تمام ✅
الآن لازم نعدّل طريقة تشغيل الحاوية حتى:

1. تشتغل **في الخلفية (background / detached mode)**.
2. ما تنحذف بعد الإيقاف (يعني من غير `--rm`).
3. نحافظ على **قاعدة بيانات SQLite** موجودة حتى بعد إعادة تشغيل الحاوية.

---

## 1️⃣ تشغيل الحاوية في الخلفية

بدل:

```bash
docker run -it --rm -p 5000:5000 myflaskapp
```

استخدم:

```bash
docker run -d --name myflaskapp -p 5000:5000 myflaskapp
```

🔹 التفسير:

* `-d` = تشغيل في الخلفية.
* `--name myflaskapp` = نعطي الحاوية اسم ثابت حتى نقدر نوقفها/نشغلها بسهولة.
* **ما في `--rm`** → الحاوية تبقى موجودة بعد التوقف.

---

## 2️⃣ إدارة الحاوية

* إيقاف الحاوية:

  ```bash
  docker stop myflaskapp
  ```

* تشغيلها مرة ثانية:

  ```bash
  docker start -a myflaskapp
  ```

* الدخول داخل الحاوية (لو تحب تفتح bash):

  ```bash
  docker exec -it myflaskapp bash
  ```

---

## 3️⃣ حماية قاعدة البيانات SQLite

SQLite تخزن البيانات في ملف مثل:

```
/app/instance/app.db
```

(المكان يعتمد على إعداد Flask عندك).

لو بقيت تستخدم نفس الحاوية فلن تضيع البيانات.
لكن الأفضل تربط **مجلد على جهازك كمجلد دائم (volume)** بحيث حتى لو مسحت الحاوية تظل قاعدة البيانات.

مثال:

```bash
docker run -d --name myflaskapp \
  -p 5000:5000 \
  -v $(pwd)/data:/app/instance \
  myflaskapp
```

🔹 الآن:

* ملفات قاعدة البيانات SQLite تنحفظ في جهازك داخل `./data` (بجوار المشروع).
* داخل الحاوية تبقى في `/app/instance`.
* حتى لو مسحت الحاوية وبنيتها من جديد → بياناتك ما تروح.

---

تحب أجهزلك نسخة محسّنة من **Dockerfile + docker-entrypoint.sh** بحيث يضمن أن قاعدة بيانات SQLite محفوظة دومًا في `/app/instance` ومربوطة بـ volume خارجي تلقائيًا؟
