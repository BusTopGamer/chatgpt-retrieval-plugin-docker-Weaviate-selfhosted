
# First stage: Python environment and poetry setup
FROM python:3.10 as requirements-stage

WORKDIR /tmp

RUN pip install poetry

COPY ./pyproject.toml ./poetry.lock* /tmp/

RUN poetry export -f requirements.txt --output requirements.txt --without-hashes

# Second stage: Installing Rust and the Python dependencies
FROM python:3.10

WORKDIR /code

# Installing curl and Rust
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y curl && \
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y && \
    /root/.cargo/bin/rustup default stable

# Copying the requirements and installing them
COPY --from=requirements-stage /tmp/requirements.txt /code/requirements.txt

# Install pip packages in the same RUN command as the Rust installation
RUN /root/.cargo/bin/rustup run stable pip install --no-cache-dir --upgrade -r /code/requirements.txt

COPY . /code/

# Heroku uses PORT, Azure App Services uses WEBSITES_PORT, Fly.io uses 8080 by default
CMD ["sh", "-c", "uvicorn server.main:app --host 0.0.0.0 --port ${PORT:-${WEBSITES_PORT:-8080}}"]

