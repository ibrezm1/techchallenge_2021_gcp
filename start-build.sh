
cbdir='gs://zeta-yen-319702-tmp/cloud-build'
gcloud builds submit --config cloudbuild.yaml \
                    --gcs-log-dir ${cbdir}/logs  \
                    --gcs-source-staging-dir ${cbdir}/stg \
                    --timeout 40s
echo "logs created in ${cbdir} press k to keep any other key to clear"
echo "in next 5 seconds"
read -rsn1 -t5 input
if [ "$input" = "k" ]; then
    echo "Logs not cleared"
else 
    gsutil rm ${cbdir}/**
fi

cd cf

# Commenting any env variables with google
sed -i.yaml 's/=/ : /g' .env
sed -i '/GOOGLE/d'  .env.yaml

# Commenting any load env files 
sed -i '/dotenv/ s/^#*/#/' *.py 

gcloud iam service-accounts enable testsvcacct@zeta-yen-319702.iam.gserviceaccount.com 

gcloud functions deploy btc-catchup \
  --project zeta-yen-319702 \
  --entry-point hello_world \
  --runtime python39 \
  --trigger-http \
  --memory 256Mi \
  --timeout 180 \
  --region us-central1 \
  --env-vars-file .env.yaml \
  --no-allow-unauthenticated \
  --service-account testsvcacct@zeta-yen-319702.iam.gserviceaccount.com \
  --max-instances 1 

gsutil -m rm gs://us.artifacts.zeta-yen-319702.appspot.com/**

# <minute> <hour> <day-of-month> <month> <day-of-week> <command>

gcloud scheduler jobs update http my-http-job \
    --schedule "0 0 1 * *"  \
    --uri https://us-central1-zeta-yen-319702.cloudfunctions.net/btc-catchup \
    --http-method GET \
    --time-zone "Australia/Sydney" \
    --oidc-service-account-email testsvcacct@zeta-yen-319702.iam.gserviceaccount.com
    #--message-body '{"name": "Scheduler"}'
