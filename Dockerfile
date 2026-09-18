# --- Build stage ---
FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app

COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . .

ARG SUPABASE_URL
ARG SUPABASE_ANON_KEY
ARG DETECTION_API_BASE_URL
ARG OPENAI_API_KEY
ARG GOOGLE_MAPS_API_KEY

RUN flutter build web --release \
    --dart-define=SUPABASE_URL=${SUPABASE_URL} \
    --dart-define=SUPABASE_ANON_KEY=${SUPABASE_ANON_KEY} \
    --dart-define=DETECTION_API_BASE_URL=${DETECTION_API_BASE_URL} \
    --dart-define=OPENAI_API_KEY=${OPENAI_API_KEY} \
    --dart-define=GOOGLE_MAPS_API_KEY=${GOOGLE_MAPS_API_KEY}

# --- Serve stage ---
FROM nginx:alpine

COPY --from=build /app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
