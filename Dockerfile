# Use the official Python base image
FROM python:3.10

# Set the working directory in the container
WORKDIR /app

# Copy the requirements file
COPY requirements.txt .

# Install the dependencies
RUN pip install --no-cache-dir -r requirements.txt

RUN playwright install

# Copy the application code
COPY ppppp.txt

# Expose the port the application will run on
EXPOSE 8000

# Run the application
CMD ["uvicorn", "server:app","--workers","4", "--host", "0.0.0.0", "--port", "8000"]
