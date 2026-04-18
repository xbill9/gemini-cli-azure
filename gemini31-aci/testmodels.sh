
cd $HOME/gemini-cli-azure/gemini31-aci
export GOOGLE_API_KEY=$GOOGLE_API_KEY
export GEMINI_API_KEY=$GOOGLE_API_KEY
export GEMINI_KEY=$GOOGLE_API_KEY

source .env

python3 list_models.py
