#!/bin/bash

#self-destruts VM after x minutes of executed the command "at"
# https://github.com/davidstanke/samples/tree/master/self-destructing-vm
# Define the metadata for the expiration time of the VM, sample 7 minutes
# --metadata SELF_DESTRUCT_INTERVAL_MINUTES=7

# use this as a startup script for a compute instance and it will self-destruct after specified interval
# (default = 24 hours)
# retrieve interval from metadata service (if available)

TIMEOUT_FROM_METADATA=$(curl -H Metadata-Flavor:Google http://metadata.google.internal/computeMetadata/v1/instance/attributes/SELF_DESTRUCT_INTERVAL_MINUTES -s)

if [ -z "$TIMEOUT_FROM_METADATA" ] || [ $TIMEOUT_FROM_METADATA == 0 ] 
  then
    TIMEOUT=1440
  else
    TIMEOUT=$TIMEOUT_FROM_METADATA
fi

# schedule the instance to delete itself

echo "gcloud compute instances delete $(hostname) --zone \
$(curl -H Metadata-Flavor:Google http://metadata.google.internal/computeMetadata/v1/instance/zone -s | cut -d/ -f4) -q" | at Now + $TIMEOUT Minutes

