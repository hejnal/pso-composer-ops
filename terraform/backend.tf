terraform {
 backend "gcs" {
   bucket  = "STATE_BUCKET"
   prefix  = "PREFIX/state"
 }
}
