#!/bin/bash

# Mac Disk Space Cleanup Script
# Created by Claude - Interactive script with confirmations and colored output

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Functions
print_header() {
  echo -e "\n${MAGENTA}========== $1 ==========${NC}\n"
}

print_subheader() {
  echo -e "\n${CYAN}>>> $1${NC}"
}

print_info() {
  echo -e "${BLUE}INFO: $1${NC}"
}

print_warning() {
  echo -e "${YELLOW}WARNING: $1${NC}"
}

print_success() {
  echo -e "${GREEN}SUCCESS: $1${NC}"
}

print_error() {
  echo -e "${RED}ERROR: $1${NC}"
}

print_size() {
  local dir="$1"
  if [ -d "$dir" ]; then
    local size=$(du -sh "$dir" 2>/dev/null | cut -f1)
    echo -e "${YELLOW}Current size of $dir: $size${NC}"
  else
    echo -e "${YELLOW}Directory $dir does not exist${NC}"
  fi
}

confirm() {
  read -p "$(echo -e ${YELLOW}$1 [y/N]${NC}) " response
  case "$response" in
    [yY][eE][sS]|[yY]) 
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

check_command() {
  if ! command -v $1 &> /dev/null; then
    print_error "$1 command not found. Skipping related cleanup steps."
    return 1
  fi
  return 0
}

clean_directory() {
  local dir="$1"
  local description="$2"
  
  if [ ! -d "$dir" ]; then
    print_info "Directory $dir does not exist. Skipping."
    return
  fi
  
  print_subheader "Cleaning $description"
  print_size "$dir"
  
  if confirm "Do you want to clean $dir?"; then
    if [ -z "$(ls -A "$dir" 2>/dev/null)" ]; then
      print_info "Directory is already empty. Skipping."
    else
      rm -rf "$dir"/* 2>/dev/null
      if [ $? -eq 0 ]; then
        print_success "Successfully cleaned $dir"
      else
        print_error "Failed to clean $dir"
      fi
    fi
  else
    print_info "Skipping cleanup of $dir"
  fi
}

clean_file() {
  local file="$1"
  local description="$2"
  
  if [ ! -f "$file" ]; then
    print_info "File $file does not exist. Skipping."
    return
  fi
  
  print_subheader "Removing $description"
  ls -lh "$file" 2>/dev/null
  
  if confirm "Do you want to remove $file?"; then
    rm -f "$file" 2>/dev/null
    if [ $? -eq 0 ]; then
      print_success "Successfully removed $file"
    else
      print_error "Failed to remove $file"
    fi
  else
    print_info "Skipping removal of $file"
  fi
}

# Main script starts here
print_header "MAC DISK SPACE CLEANUP SCRIPT"
print_info "This script will help you clean up disk space on your Mac."
print_warning "It will ask for confirmation before deleting any files."
echo ""

if ! confirm "Ready to proceed with the cleanup?"; then
  print_info "Cleanup cancelled by user."
  exit 0
fi

# ==============================================
# 1. iOS Developer Cleanup
# ==============================================
print_header "iOS DEVELOPER CLEANUP"

# Xcode check
if check_command xcrun; then
  print_subheader "Removing unavailable iOS simulators"
  print_info "This will remove simulators that are no longer available."
  
  if confirm "Do you want to remove unavailable simulators?"; then
    xcrun simctl delete unavailable
    print_success "Removed unavailable simulators"
  else
    print_info "Skipping simulator cleanup"
  fi
fi

# CoreSimulator Caches
print_subheader "Cleaning CoreSimulator Caches"
CORESIM_CACHES="$HOME/Library/Developer/CoreSimulator/Caches"
print_size "$CORESIM_CACHES"

if confirm "Do you want to clean CoreSimulator caches? (These will be regenerated as needed)"; then
  if [ -d "$CORESIM_CACHES" ]; then
    rm -rf "$CORESIM_CACHES"/* 2>/dev/null
    if [ $? -eq 0 ]; then
      print_success "Successfully cleaned CoreSimulator caches"
    else
      print_error "Failed to clean CoreSimulator caches"
    fi
  else
    print_info "CoreSimulator Caches directory does not exist. Skipping."
  fi
else
  print_info "Skipping CoreSimulator caches cleanup"
fi

# Xcode Preview Simulator Devices
PREVIEW_DEVICES="$HOME/Library/Developer/Xcode/UserData/Previews/Simulator Devices"
print_subheader "Cleaning Xcode Preview Simulator Devices"
print_size "$PREVIEW_DEVICES"

if confirm "Do you want to clean Xcode Preview Simulator Devices?"; then
  if [ -d "$PREVIEW_DEVICES" ]; then
    rm -rf "$PREVIEW_DEVICES"/* 2>/dev/null
    if [ $? -eq 0 ]; then
      print_success "Successfully cleaned Xcode Preview Simulator Devices"
    else
      print_error "Failed to clean Xcode Preview Simulator Devices"
    fi
  else
    print_info "Xcode Preview Simulator Devices directory does not exist. Skipping."
  fi
else
  print_info "Skipping Xcode Preview Simulator Devices cleanup"
fi

# iOS Device Support
IOS_DEVICE_SUPPORT="$HOME/Library/Developer/Xcode/iOS DeviceSupport"
print_subheader "Cleaning iOS Device Support"
print_size "$IOS_DEVICE_SUPPORT"

if [ -d "$IOS_DEVICE_SUPPORT" ]; then
  echo -e "${BLUE}Available iOS Device Support versions:${NC}"
  ls -la "$IOS_DEVICE_SUPPORT" | grep -v "^total" | grep -v "^d.*\.\.$"
  
  print_warning "It's recommended to keep the latest 2-3 iOS versions you actively develop for."
  print_info "You'll be asked about each version individually."

  # Process each iOS version
  for version_dir in "$IOS_DEVICE_SUPPORT"/*; do
    if [ -d "$version_dir" ]; then
      version_name=$(basename "$version_dir")
      version_size=$(du -sh "$version_dir" 2>/dev/null | cut -f1)
      
      if confirm "Remove iOS Device Support for $version_name (Size: $version_size)?"; then
        rm -rf "$version_dir" 2>/dev/null
        if [ $? -eq 0 ]; then
          print_success "Removed iOS Device Support for $version_name"
        else
          print_error "Failed to remove iOS Device Support for $version_name"
        fi
      else
        print_info "Keeping iOS Device Support for $version_name"
      fi
    fi
  done
else
  print_info "iOS Device Support directory does not exist. Skipping."
fi

# macOS Device Support
MACOS_DEVICE_SUPPORT="$HOME/Library/Developer/Xcode/macOS DeviceSupport"
print_subheader "Cleaning macOS Device Support"
print_size "$MACOS_DEVICE_SUPPORT"

if [ -d "$MACOS_DEVICE_SUPPORT" ]; then
  echo -e "${BLUE}Available macOS Device Support versions:${NC}"
  ls -la "$MACOS_DEVICE_SUPPORT" | grep -v "^total" | grep -v "^d.*\.\.$"
  
  print_warning "It's recommended to keep the latest macOS versions you actively develop for."
  print_info "You'll be asked about each version individually."

  # Process each macOS version
  for version_dir in "$MACOS_DEVICE_SUPPORT"/*; do
    if [ -d "$version_dir" ]; then
      version_name=$(basename "$version_dir")
      version_size=$(du -sh "$version_dir" 2>/dev/null | cut -f1)
      
      if confirm "Remove macOS Device Support for $version_name (Size: $version_size)?"; then
        rm -rf "$version_dir" 2>/dev/null
        if [ $? -eq 0 ]; then
          print_success "Removed macOS Device Support for $version_name"
        else
          print_error "Failed to remove macOS Device Support for $version_name"
        fi
      else
        print_info "Keeping macOS Device Support for $version_name"
      fi
    fi
  done
else
  print_info "macOS Device Support directory does not exist. Skipping."
fi

# XCPGDevices
XCPG_DEVICES="$HOME/Library/Developer/XCPGDevices"
print_subheader "Cleaning XCPGDevices"
print_size "$XCPG_DEVICES"

if confirm "Do you want to clean XCPGDevices? (Testing devices)"; then
  if [ -d "$XCPG_DEVICES" ]; then
    rm -rf "$XCPG_DEVICES"/* 2>/dev/null
    if [ $? -eq 0 ]; then
      print_success "Successfully cleaned XCPGDevices"
    else
      print_error "Failed to clean XCPGDevices"
    fi
  else
    print_info "XCPGDevices directory does not exist. Skipping."
  fi
else
  print_info "Skipping XCPGDevices cleanup"
fi

# Xcode Archives (optional)
XCODE_ARCHIVES="$HOME/Library/Developer/Xcode/Archives"
print_subheader "Cleaning Xcode Archives"
print_size "$XCODE_ARCHIVES"

if [ -d "$XCODE_ARCHIVES" ]; then
  print_warning "Xcode Archives contain your app build history and may be needed for App Store submissions."
  if confirm "Do you want to list and potentially clean Xcode Archives?"; then
    echo -e "${BLUE}Available Xcode Archive folders:${NC}"
    ls -la "$XCODE_ARCHIVES" | grep -v "^total" | grep -v "^d.*\.\.$"
    
    if confirm "Do you want to remove ALL Xcode Archives? (NOT RECOMMENDED unless you're sure)"; then
      rm -rf "$XCODE_ARCHIVES"/* 2>/dev/null
      if [ $? -eq 0 ]; then
        print_success "Removed all Xcode Archives"
      else
        print_error "Failed to remove Xcode Archives"
      fi
    else
      print_info "Keeping Xcode Archives"
    fi
  else
    print_info "Skipping Xcode Archives cleanup"
  fi
else
  print_info "Xcode Archives directory does not exist. Skipping."
fi

# Xcode Derived Data
DERIVED_DATA="$HOME/Library/Developer/Xcode/DerivedData"
print_subheader "Cleaning Xcode Derived Data"
print_size "$DERIVED_DATA"

if confirm "Do you want to clean Xcode Derived Data? (Safe to remove)"; then
  if [ -d "$DERIVED_DATA" ]; then
    rm -rf "$DERIVED_DATA"/* 2>/dev/null
    if [ $? -eq 0 ]; then
      print_success "Successfully cleaned Xcode Derived Data"
    else
      print_error "Failed to clean Xcode Derived Data"
    fi
  else
    print_info "Xcode Derived Data directory does not exist. Skipping."
  fi
else
  print_info "Skipping Xcode Derived Data cleanup"
fi

# ==============================================
# 2. Android Development Cleanup
# ==============================================
print_header "ANDROID DEVELOPMENT CLEANUP"

# Android SDK Build Tools
ANDROID_SDK="$HOME/Library/Android/sdk"
ANDROID_BUILD_TOOLS="$ANDROID_SDK/build-tools"
print_subheader "Cleaning Android SDK Build Tools"

if [ -d "$ANDROID_BUILD_TOOLS" ]; then
  print_size "$ANDROID_BUILD_TOOLS"
  echo -e "${BLUE}Available Android Build Tool versions:${NC}"
  ls -la "$ANDROID_BUILD_TOOLS" | grep -v "^total" | grep -v "^d.*\.\.$"
  
  print_warning "It's recommended to keep the latest Android build tools you actively use."
  print_info "You'll be asked about each version individually."

  # Process each Android build tools version
  for version_dir in "$ANDROID_BUILD_TOOLS"/*; do
    if [ -d "$version_dir" ]; then
      version_name=$(basename "$version_dir")
      version_size=$(du -sh "$version_dir" 2>/dev/null | cut -f1)
      
      if confirm "Remove Android Build Tools version $version_name (Size: $version_size)?"; then
        rm -rf "$version_dir" 2>/dev/null
        if [ $? -eq 0 ]; then
          print_success "Removed Android Build Tools version $version_name"
        else
          print_error "Failed to remove Android Build Tools version $version_name"
        fi
      else
        print_info "Keeping Android Build Tools version $version_name"
      fi
    fi
  done
else
  print_info "Android Build Tools directory does not exist. Skipping."
fi

# Android SDK Platforms
ANDROID_PLATFORMS="$ANDROID_SDK/platforms"
print_subheader "Cleaning Android SDK Platforms"

if [ -d "$ANDROID_PLATFORMS" ]; then
  print_size "$ANDROID_PLATFORMS"
  echo -e "${BLUE}Available Android Platform versions:${NC}"
  ls -la "$ANDROID_PLATFORMS" | grep -v "^total" | grep -v "^d.*\.\.$"
  
  print_warning "It's recommended to keep the Android platforms you actively target."
  print_info "You'll be asked about each version individually."

  # Process each Android platform version
  for version_dir in "$ANDROID_PLATFORMS"/*; do
    if [ -d "$version_dir" ]; then
      version_name=$(basename "$version_dir")
      version_size=$(du -sh "$version_dir" 2>/dev/null | cut -f1)
      
      if confirm "Remove Android Platform $version_name (Size: $version_size)?"; then
        rm -rf "$version_dir" 2>/dev/null
        if [ $? -eq 0 ]; then
          print_success "Removed Android Platform $version_name"
        else
          print_error "Failed to remove Android Platform $version_name"
        fi
      else
        print_info "Keeping Android Platform $version_name"
      fi
    fi
  done
else
  print_info "Android Platforms directory does not exist. Skipping."
fi

# Android SDK System Images
ANDROID_SYSTEM_IMAGES="$ANDROID_SDK/system-images"
print_subheader "Cleaning Android System Images"

if [ -d "$ANDROID_SYSTEM_IMAGES" ]; then
  print_size "$ANDROID_SYSTEM_IMAGES"
  echo -e "${BLUE}Available Android System Image folders:${NC}"
  find "$ANDROID_SYSTEM_IMAGES" -type d -mindepth 2 -maxdepth 2 | sort
  
  print_warning "These are emulator system images. Only remove those you don't use."
  
  if confirm "Do you want to review and potentially remove Android system images?"; then
    # Process each Android system image folder
    for android_ver_dir in "$ANDROID_SYSTEM_IMAGES"/*; do
      if [ -d "$android_ver_dir" ]; then
        android_ver=$(basename "$android_ver_dir")
        
        for image_type_dir in "$android_ver_dir"/*; do
          if [ -d "$image_type_dir" ]; then
            image_type=$(basename "$image_type_dir")
            image_size=$(du -sh "$image_type_dir" 2>/dev/null | cut -f1)
            
            if confirm "Remove Android $android_ver system image type $image_type (Size: $image_size)?"; then
              rm -rf "$image_type_dir" 2>/dev/null
              if [ $? -eq 0 ]; then
                print_success "Removed Android $android_ver system image type $image_type"
              else
                print_error "Failed to remove Android system image"
              fi
            else
              print_info "Keeping Android $android_ver system image type $image_type"
            fi
          fi
        done
      fi
    done
  else
    print_info "Skipping Android System Images cleanup"
  fi
else
  print_info "Android System Images directory does not exist. Skipping."
fi

# Android cache
ANDROID_CACHE="$HOME/.android/cache"
print_subheader "Cleaning Android Cache"
print_size "$ANDROID_CACHE"

if confirm "Do you want to clean Android cache?"; then
  if [ -d "$ANDROID_CACHE" ]; then
    rm -rf "$ANDROID_CACHE"/* 2>/dev/null
    if [ $? -eq 0 ]; then
      print_success "Successfully cleaned Android cache"
    else
      print_error "Failed to clean Android cache"
    fi
  else
    print_info "Android Cache directory does not exist. Skipping."
  fi
else
  print_info "Skipping Android cache cleanup"
fi

# Gradle cache
GRADLE_CACHE="$HOME/.gradle/caches"
print_subheader "Cleaning Gradle Cache"
print_size "$GRADLE_CACHE"

if confirm "Do you want to clean Gradle cache? (Will be downloaded again as needed)"; then
  if [ -d "$GRADLE_CACHE" ]; then
    rm -rf "$GRADLE_CACHE"/* 2>/dev/null
    if [ $? -eq 0 ]; then
      print_success "Successfully cleaned Gradle cache"
    else
      print_error "Failed to clean Gradle cache"
    fi
  else
    print_info "Gradle Cache directory does not exist. Skipping."
  fi
else
  print_info "Skipping Gradle cache cleanup"
fi

# ==============================================
# 3. General Cache Cleanup
# ==============================================
print_header "GENERAL CACHE CLEANUP"

# Array of cache directories to clean
CACHE_DIRS=(
  "$HOME/Library/Caches/Google:Google Cache (Chrome, etc.)"
  "$HOME/Library/Caches/Yarn:Yarn Package Manager Cache"
  "$HOME/Library/Caches/org.swift.swiftpm:Swift Package Manager Cache"
  "$HOME/Library/Caches/argmax-sdk-swift:Argmax SDK Swift Cache"
  "$HOME/Library/Caches/typescript:TypeScript Cache"
  "$HOME/Library/Caches/Arc:Arc Browser Cache"
  "$HOME/Library/Caches/com.tinyspeck.slackmacgap.ShipIt:Slack Updater Cache"
  "$HOME/Library/Caches/com.spotify.client:Spotify Cache"
  "$HOME/Library/Caches/Adobe:Adobe Cache"
  "$HOME/Library/Caches/Adobe Camera Raw 2:Adobe Camera Raw Cache"
  "$HOME/Library/Caches/com.apple.amp.itmstransporter:iTunes Transporter Cache"
  "$HOME/Library/Caches/node-gyp:Node Gyp Cache"
  "$HOME/Library/Caches/loom-updater:Loom Updater Cache"
  "$HOME/Library/Caches/@trezorsuite-desktop-updater:Trezor Suite Updater Cache"
  "$HOME/Library/Caches/pip:Python pip Cache"
  "$HOME/Library/Caches/go-build:Go Build Cache"
)

for cache_entry in "${CACHE_DIRS[@]}"; do
  IFS=':' read -r cache_dir cache_desc <<< "$cache_entry"
  clean_directory "$cache_dir" "$cache_desc"
done

# Homebrew cache (using brew command)
if check_command brew; then
  print_subheader "Cleaning Homebrew Cache"
  
  if confirm "Do you want to clean Homebrew cache? (This frees up space from old package versions)"; then
    echo -e "${BLUE}Running brew cleanup...${NC}"
    brew cleanup -s
    if [ $? -eq 0 ]; then
      print_success "Successfully cleaned Homebrew cache"
    else
      print_error "Failed to clean Homebrew cache"
    fi
  else
    print_info "Skipping Homebrew cache cleanup"
  fi
fi

# CocoaPods cache (using pod command)
if check_command pod; then
  print_subheader "Cleaning CocoaPods Cache"
  
  if confirm "Do you want to clean CocoaPods cache?"; then
    echo -e "${BLUE}Running pod cache clean...${NC}"
    pod cache clean --all
    if [ $? -eq 0 ]; then
      print_success "Successfully cleaned CocoaPods cache"
    else
      print_error "Failed to clean CocoaPods cache"
    fi
  else
    print_info "Skipping CocoaPods cache cleanup"
  fi
fi

# ==============================================
# 4. Application Support Cleanup (selective)
# ==============================================
print_header "APPLICATION SUPPORT CLEANUP (SELECTIVE)"
print_warning "This section is more selective - only clean folders you're sure about"

# Array of potential application support directories to clean
APP_SUPPORT_DIRS=(
  "$HOME/Library/Application Support/Caches:Application Support Cache Folder"
  "$HOME/Library/Application Support/Google:Google Application Data"
  "$HOME/Library/Application Support/rambox:Rambox Application Data"
  "$HOME/Library/Application Support/Slack:Slack Application Data"
  "$HOME/Library/Application Support/MacWhisper:MacWhisper Application Data"
)

for app_entry in "${APP_SUPPORT_DIRS[@]}"; do
  IFS=':' read -r app_dir app_desc <<< "$app_entry"
  
  if [ -d "$app_dir" ]; then
    print_subheader "Reviewing $app_desc"
    print_size "$app_dir"
    print_warning "Cleaning this might affect application settings or cached data"
    
    if confirm "Do you want to REVIEW $app_dir contents? (No deletion yet)"; then
      echo -e "${BLUE}Contents of $app_dir:${NC}"
      ls -la "$app_dir" | head -n 20
      
      if [[ $(ls -A "$app_dir" | wc -l) -gt 20 ]]; then
        echo -e "${YELLOW}... and more files (showing first 20 only)${NC}"
      fi
      
      if confirm "Do you want to DELETE contents of $app_dir? (USE WITH CAUTION)"; then
        rm -rf "$app_dir"/* 2>/dev/null
        if [ $? -eq 0 ]; then
          print_success "Successfully cleaned $app_dir"
        else
          print_error "Failed to clean $app_dir"
        fi
      else
        print_info "Skipping deletion of $app_dir contents"
      fi
    else
      print_info "Skipping review of $app_dir"
    fi
  else
    print_info "$app_dir does not exist. Skipping."
  fi
done

# ==============================================
# Final summary
# ==============================================
print_header "CLEANUP COMPLETE"
print_info "Disk cleanup process has finished."
print_info "To see how much space was freed, run:"
echo -e "${GREEN}df -h${NC}"

print_warning "Remember that some applications may need to rebuild their caches when next launched."
print_warning "Some developer tools may need to download components again when used."

echo ""
echo -e "${MAGENTA}Thank you for using the Mac Disk Space Cleanup Script!${NC}"