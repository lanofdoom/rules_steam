import requests
import argparse
import hashlib
import re
import logging
import time
import humanize
from jinja2 import Template

DEFAULT_GITHUB_DOMAIN = "api.github.com"
DEFAULT_GITHUB_OWNERREPO = "SteamRE/DepotDownloader"
DEFAULT_LINUX_BINARY_REGEX = r".*linux-x64.*\.zip$"

TEMPLATE = """
LINUX_RELEASE_URL="{{linux_release_url}}"
LINUX_RELEASE_SHA256="{{linux_release_sha256}}"
"""

logging.basicConfig(level=logging.INFO, format='%(levelname)s: %(message)s')



def download_and_calculate_sha256(url):
    """Download file in memory and calculate SHA-256 checksum"""

    logging.info(f"starting download: {url}")
    start_time = time.time()

    # Download the file
    response = requests.get(url)
    response.raise_for_status()  # Ensure we got a successful response

    # Measure download time and file size
    download_time = time.time() - start_time
    file_size_bytes = len(response.content)
    file_size_human = humanize.naturalsize(
        file_size_bytes)  # Convert size to human-readable format
    logging.info(
        f"downloaded {file_size_human} in {download_time:.2f} seconds")

    # Calculate SHA-256 checksum
    sha256_hash = hashlib.sha256()
    sha256_hash.update(response.content)
    checksum = sha256_hash.hexdigest()

    logging.info(f"calculated file hash {checksum}")

    return checksum


def find_release(api_url, release_pattern):
    """Fetch the latest GitHub releases and find the Linux binary."""
    response = requests.get(api_url)
    response.raise_for_status()  # Raise an error for bad HTTP responses
    releases = response.json()

    compiled_regex = re.compile(release_pattern)

    for release in releases:
        for asset in release.get('assets', []):
            asset_name = asset['name']
            if compiled_regex.match(asset_name):
                logging.info(f"found matching binary: {asset_name}")
                download_url = asset['browser_download_url']

                return download_url, download_and_calculate_sha256(download_url)


def main():
    parser = argparse.ArgumentParser(
        description="Find the latest release binary from a GitHub repository.")

    parser.add_argument('--owner_repo',
                        type=str,
                        default=DEFAULT_GITHUB_OWNERREPO,
                        help="GitHub repository in 'owner/repo' format.")

    parser.add_argument('--github_domain',
                        type=str,
                        default=DEFAULT_GITHUB_DOMAIN,
                        help="GitHub API domain.")

    parser.add_argument('--release_pattern',
                        type=str,
                        default=DEFAULT_LINUX_BINARY_REGEX,
                        help="Regular expression to match release files")

    args = parser.parse_args()

    api_url = f"https://{args.github_domain}/repos/{args.owner_repo}/releases"

    linux_release_url, linux_release_sha256 = find_release(
        api_url, args.release_pattern)

    if linux_release_url and linux_release_sha256:
        content = Template(TEMPLATE).render(
                                  linux_release_url=linux_release_url,
                                  linux_release_sha256=linux_release_sha256)
        logging.info(f"rendered content is {humanize.naturalsize(len(content))}")
        print(content)


if __name__ == "__main__":
    main()
