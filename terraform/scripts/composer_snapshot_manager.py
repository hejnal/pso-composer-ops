from google.cloud.orchestration.airflow import service_v1
from google.cloud import storage
import argparse
import time
import sys

def get_latest_snapshot(bucket_name):
    """Fetches the path of the latest snapshot in the given GCS bucket."""

    storage_client = storage.Client()
    bucket = storage_client.bucket(bucket_name)
    blobs = list(bucket.list_blobs(prefix=""))
    blobs.sort(key=lambda blob: blob.time_created, reverse=True)

    if blobs:
        # Extract the snapshot folder path from the first blob
        snapshot_folder = "/".join(blobs[0].name.split("/")[:-1])
        return "gs://" + bucket_name + "/" + snapshot_folder
    else:
        raise ValueError(f"No snapshots found in bucket: {bucket_name}")

def create_composer_snapshot(client, environment_name, snapshot_location):
    """Creates a Composer snapshot in the given location."""

    max_retries = 5
    retry_delay = 30  # seconds

    for i in range(max_retries):
        environment = client.get_environment(name=environment_name)
        if environment.state == 2:  # RUNNING state
            request = service_v1.SaveSnapshotRequest(
                environment=environment_name, snapshot_location=snapshot_location
            )
            operation = client.save_snapshot(request=request)
            print("Waiting for the operation to complete...")
            print(operation)
            wait_for_composer_status(client, environment_name, target_status=2)
            return  # Snapshot created successfully
        else:
            print(f"Environment is in {environment.state} state. Retrying in {retry_delay} seconds...")
            time.sleep(retry_delay)

    raise Exception(f"Failed to create snapshot after {max_retries} retries.")

def restore_composer_snapshot(client, environment_name, snapshot_path):
    """Restores a Composer environment from the given snapshot."""

    request = service_v1.LoadSnapshotRequest(
        environment=environment_name, snapshot_path=snapshot_path
    )
    operation = client.load_snapshot(request=request)
    print("Waiting for the operation to complete...")
    print(operation)

def wait_for_composer_status(client, environment_name, target_status):
    """Waits for a Composer environment to reach the target status."""

    while True:
        environment = client.get_environment(name=environment_name)
        print(f"Composer state is: {environment.state}")
        if environment.state == target_status:
            break
        elif environment.state not in [2, 3]:
            raise Exception("Environment entered an ERROR state.")
        else:
            print('Composer state is updating')
            time.sleep(5)

def main():
    # Parse command-line arguments using argparse
    parser = argparse.ArgumentParser(description="Manage Composer snapshots.")
    parser.add_argument("--project", required=True, help="Google Cloud project ID.")
    parser.add_argument("--location", required=True, help="Google Cloud location (region).")
    parser.add_argument("--environment", required=True, help="Composer environment name.")
    parser.add_argument("--snapshot_bucket", required=True, help="GCS bucket for storing snapshots.")
    parser.add_argument("--operation", required=True, choices=["create", "restore"], help="Operation to perform: 'create' or 'restore'.")
    args = parser.parse_args()

    project_id = args.project
    region = args.location
    environment_name = f"projects/{project_id}/locations/{region}/environments/{args.environment}"
    snapshot_bucket = args.snapshot_bucket

    print(f"Project ID: {project_id}")
    print(f"Region: {region}")
    print(f"Environment Name: {environment_name}")
    print(f"Snapshot Bucket: {snapshot_bucket}")

    client = service_v1.EnvironmentsClient()

    if args.operation == "create":
        snapshot_location = f"gs://{snapshot_bucket}"  # Construct the full GCS URI
        create_composer_snapshot(client, environment_name, snapshot_location)
    elif args.operation == "restore":
        try:
            latest_snapshot_path = get_latest_snapshot(snapshot_bucket)
            print(f"Latest Snapshot Path: {latest_snapshot_path}")
            restore_composer_snapshot(client, environment_name, latest_snapshot_path)
        except ValueError as e:
            print(f"Error: {e}")
            sys.exit(1)

    wait_for_composer_status(client, environment_name, target_status=2)

    if args.operation == "create":
        print(f"Created Composer Snapshot for Environment: {environment_name}")
    elif args.operation == "restore":
        print(f"Restored from the Composer Snapshot for Environment: {environment_name}")

if __name__ == "__main__":
    main()