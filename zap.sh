#!/bin/bash

# Ensure the script is executable
chmod 777 $(pwd)
echo "User ID and Group ID: $(id -u):$(id -g)"

# Start port forwarding in the background
echo "Starting port-forward for numeric-service..."
kubectl port-forward svc/numeric-service 9091:8080 &
PORT_FORWARD_PID=$!
echo "Port-forward started with PID: $PORT_FORWARD_PID"

# Allow time for the port-forward to establish
sleep 5

# Set URL for OWASP ZAP API Scan
URL="http://localhost:9091/v3/api-docs"
echo "API Docs URL: $URL"

# Run OWASP ZAP API Scan with Custom Rules
echo "Running OWASP ZAP API Scan with Custom Rules..."
docker run -v $(pwd):/zap/wrk/:rw -t ictu/zap2docker-weekly zap-api-scan.py -t $URL -f openapi -c zap_rules -r zap_report.html
exit_code=$?

# Stop port forwarding
echo "Stopping port-forward with PID: $PORT_FORWARD_PID"
kill $PORT_FORWARD_PID
wait $PORT_FORWARD_PID 2>/dev/null

# Generate HTML Report
echo "Generating OWASP ZAP HTML Report..."
mkdir -p owasp-zap-report
mv zap_report.html owasp-zap-report
echo "Report saved to owasp-zap-report/zap_report.html"

echo "Exit Code: $exit_code"

# Handle Exit Codes
if [[ ${exit_code} -ne 0 ]]; then
    echo "❗ OWASP ZAP Report has detected Low/Medium/High Risk. Please check the HTML Report."
    exit 1
else
    echo "✅ OWASP ZAP did not report any Risk."
    exit 0
fi
