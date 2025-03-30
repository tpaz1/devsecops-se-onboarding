#!/bin/bash

# integration-test.sh

# Start port forwarding in the background
echo "Starting port-forward for numeric-service..."
kubectl port-forward svc/numeric-service 9091:8080 &
PORT_FORWARD_PID=$!
echo "Port-forward started with PID: $PORT_FORWARD_PID"

# Allow some time for the port-forward to establish
sleep 5

# Test URL
URL="http://localhost:9091/increment/99"

echo "Testing URL: $URL"

# Perform retries
MAX_RETRIES=5
for (( i=1; i<=MAX_RETRIES; i++ ))
do
    echo "Attempt $i/$MAX_RETRIES - Sending request to $URL"

    # Get the response and HTTP status code
    response=$(curl -s $URL)
    http_code=$(curl -s -o /dev/null -w "%{http_code}" $URL)

    echo "Response: $response"
    echo "HTTP Code: $http_code"

    # Check if response and HTTP code are valid
    if [[ "$response" == "100" && "$http_code" == "200" ]]; then
        echo "✅ Increment Test Passed"
        echo "✅ HTTP Status Code Test Passed"
        break
    else
        echo "❗ Test failed, retrying in 5 seconds..."
        sleep 5
    fi
done

# Stop port forwarding
echo "Stopping port-forward with PID: $PORT_FORWARD_PID"
kill $PORT_FORWARD_PID
wait $PORT_FORWARD_PID 2>/dev/null

# Check if the test failed after retries
if [[ "$response" != "100" || "$http_code" != "200" ]]; then
    echo "❌ Tests failed after $MAX_RETRIES attempts."
    exit 1
else
    echo "✅ All tests passed successfully!"
    exit 0
fi