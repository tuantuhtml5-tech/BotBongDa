FROM python:3.12-slim
ENV PYTHONUNBUFFERED=1 PYTHONDONTWRITEBYTECODE=1 PORT=8080 DB_PATH=/data/bot.sqlite3
WORKDIR /app
RUN useradd --uid 10001 --create-home bot && mkdir /data && chown bot:bot /data
COPY --chown=bot:bot bot /app/bot
COPY --chown=bot:bot docs /app/docs
EXPOSE 8080
CMD ["python", "-m", "bot.entrypoint"]
