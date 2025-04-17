#!/bin/bash

# Mac Disk Space Cleanup Script
# Interactive script with confirmations, colored output and config file support

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;36m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration file path
CONFIG_FILE="$HOME/.mac-dev-cleanup-config.json"
DEFAULT_CONFIG_FILE="./mac-dev-cleanup-config.json"

# ==============================================
# Utility Functions
# ==============================================
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

# ==============================================
# Safety Functions
# ==============================================
is_safe_path() {
  local path="$1"
  
  # Expand home directory if needed
  path="${path/#\~/$HOME}"
  
  # Basic safety checks
  if [[ "$path" == "/" || 
        "$path" == "/System" || 
        "$path" == "/Library" || 
        "$path" == "/Applications" || 
        "$path" == "/Users" ||
        "$path" == "/bin" ||
        "$path" == "/sbin" ||
        "$path" == "/usr" ]]; then
    print_error "SAFETY CHECK FAILED: Cannot clean system directory $path"
    return 1
  fi
  
  # Check if path is under user home
  if [[ "$path" == "$HOME"* ]]; then
    # Additional safety checks for important user directories
    if [[ "$path" == "$HOME" || 
          "$path" == "$HOME/Documents" || 
          "$path" == "$HOME/Desktop" || 
          "$path" == "$HOME/Pictures" || 
          "$path" == "$HOME/Music" || 
          "$path" == "$HOME/Movies" ]]; then
      print_error "SAFETY CHECK FAILED: Cannot clean important user directory $path"
      return 1
    fi
    return 0
  fi
  
  # Path is outside home directory - be extra cautious
  print_warning "Path $path is outside your home directory"
  if confirm "This is potentially dangerous. Are you ABSOLUTELY sure you want to proceed?"; then
    return 0
  else
    return 1
  fi
}

# ==============================================
# Configuration Functions
# ==============================================
create_default_config() {
  local config_file="$1"
  
  print_info "Creating default configuration file at $config_file"
  
  cat > "$config_file" << 'EOF'
{
  "cache_directories": [
    {
      "path": "~/Library/Caches/Google",
      "description": "Google Cache (Chrome, etc.)",
      "enabled": true
    },
    {
      "path": "~/Library/Caches/Yarn",
      "description": "Yarn Package Manager Cache",
      "enabled": true
    },
    {
      "path": "~/Library/Caches/org.swift.swiftpm",
      "description": "Swift Package Manager Cache",
      "enabled": true
    },
    {
      "path": "~/Library/Caches/typescript",
      "description": "TypeScript Cache",
      "enabled": true
    },
    {
      "path": "~/Library/Caches/Arc",
      "description": "Arc Browser Cache",
      "enabled": true
    }
  ],
  "developer_directories": [
    {
      "path": "~/Library/Developer/CoreSimulator/Caches",
      "description": "iOS Simulator Caches",
      "enabled": true
    },
    {
      "path": "~/Library/Developer/Xcode/DerivedData",
      "description": "Xcode Derived Data",
      "enabled": true
    },
    {
      "path": "~/Library/Developer/Xcode/Archives",
      "description": "Xcode Archives",
      "enabled": false
    },
    {
      "path": "~/Library/Developer/XCPGDevices",
      "description": "Xcode Testing Devices",
      "enabled": true
    }
  ],
  "application_support_directories": [
    {
      "path": "~/Library/Application Support/Caches",
      "description": "Application Support Cache Folder",
      "enabled": true
    },
    {
      "path": "~/Library/Application Support/Google",
      "description": "Google Application Data",
      "enabled": false
    }
  ],
  "android_directories": [
    {
      "path": "~/.android/cache",
      "description": "Android Cache",
      "enabled": true
    },
    {
      "path": "~/.gradle/caches",
      "description": "Gradle Cache",
      "enabled": true
    }
  ],
  "device_support": {
    "clean_ios_device_support": true,
    "keep_latest_ios_versions": 2,
    "clean_macos_device_support": true,
    "keep_latest_macos_versions": 1
  },
  "android_sdk": {
    "clean_build_tools": true,
    "clean_platforms": true,
    "clean_system_images": true
  }
}
EOF

  print_success "Default configuration file created"
}

load_config() {
  local config_file="$1"
  
  if [ ! -f "$config_file" ]; then
    print_warning "Configuration file not found at $config_file"
    
    if [ "$config_file" != "$DEFAULT_CONFIG_FILE" ] && [ -f "$DEFAULT_CONFIG_FILE" ]; then
      print_info "Using default configuration file at $DEFAULT_CONFIG_FILE"
      config_file="$DEFAULT_CONFIG_FILE"
    else
      if confirm "Do you want to create a default configuration file?"; then
        if [ "$config_file" == "$CONFIG_FILE" ]; then
          create_default_config "$config_file"
        else
          create_default_config "$DEFAULT_CONFIG_FILE"
          config_file="$DEFAULT_CONFIG_FILE"
        fi
      else
        print_error "Cannot continue without configuration file"
        exit 1
      fi
    fi
  fi
  
  # Check if jq is installed
  if ! command -v jq &> /dev/null; then
    print_error "jq is not installed. Cannot parse JSON configuration."
    print_info "Install jq using: brew install jq"
    print_info "Or manually edit the script to include your directories."
    exit 1
  fi
  
  print_info "Loading configuration from $config_file"
  
  # Validate JSON syntax
  if ! jq empty "$config_file" 2>/dev/null; then
    print_error "Invalid JSON syntax in configuration file"
    exit 1
  fi
  
  return 0
}

# ==============================================
# Helper Functions
# ==============================================
get_sorted_directories() {
  local dir="$1"
  local pattern="$2"
  
  # Use find to get directories and sort by modification time
  find "$dir" -maxdepth 1 -type d -name "*" -exec stat -f "%m %N" {} \; | \
    sort -nr | \
    cut -d' ' -f2- | \
    while IFS= read -r line; do
      # Get just the basename and check if it matches the pattern
      basename=$(basename "$line")
      if [[ "$basename" =~ $pattern ]]; then
        echo "$basename"
      fi
    done
}

# ==============================================
# Cleanup Functions
# ==============================================
clean_directory() {
  local dir="$1"
  local description="$2"
  
  # Expand home directory if needed
  dir="${dir/#\~/$HOME}"
  
  if [ ! -d "$dir" ]; then
    print_info "Directory $dir does not exist. Skipping."
    return
  fi
  
  # Safety check
  if ! is_safe_path "$dir"; then
    print_warning "Skipping $dir due to safety check"
    return
  fi
  
  print_subheader "Cleaning $description"
  print_size "$dir"
  
  if confirm "Do you want to clean $dir?"; then
    if [ -z "$(ls -A "$dir" 2>/dev/null)" ]; then
      print_info "Directory is already empty. Skipping."
    else
      if [[ -z "$dir" || "$dir" == "/" ]]; then
        print_error "Invalid or empty directory path: '$dir'. Skipping."
        return
      fi
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
  
  # Expand home directory if needed
  file="${file/#\~/$HOME}"
  
  if [ ! -f "$file" ]; then
    print_info "File $file does not exist. Skipping."
    return
  fi
  
  # Safety check
  if ! is_safe_path "$file"; then
    print_warning "Skipping $file due to safety check"
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

process_directory_section() {
  local config_file="$1"
  local section="$2"
  
  local count=$(jq ".$section | length" "$config_file")
  
  for (( i=0; i<$count; i++ )); do
    local enabled=$(jq -r ".$section[$i].enabled" "$config_file")
    
    if [ "$enabled" = "true" ]; then
      local path=$(jq -r ".$section[$i].path" "$config_file")
      local description=$(jq -r ".$section[$i].description" "$config_file")
      
      clean_directory "$path" "$description"
    fi
  done
}

# ==============================================
# Main Cleanup Functions
# ==============================================
clean_ios_developer() {
  print_header "iOS DEVELOPER CLEANUP"
  
  # Process developer directories from config
  process_directory_section "$CONFIG_FILE" "developer_directories"
  
  # Xcode check
  if check_command xcrun; then
    clean_simulators
  fi
  
  clean_ios_device_support
  clean_macos_device_support
}

clean_android_developer() {
  print_header "ANDROID DEVELOPMENT CLEANUP"
  
  # Process android directories from config
  process_directory_section "$CONFIG_FILE" "android_directories"
  
  clean_android_build_tools
  clean_android_platforms
  clean_android_system_images
}

clean_general_cache() {
  print_header "GENERAL CACHE CLEANUP"
  
  # Process cache directories from config
  process_directory_section "$CONFIG_FILE" "cache_directories"
  
  clean_homebrew_cache
  clean_cocoapods_cache
}

clean_application_support() {
  print_header "APPLICATION SUPPORT CLEANUP (SELECTIVE)"
  print_warning "This section is more selective - only clean folders you're sure about"
  
  # Process application support directories from config
  process_directory_section "$CONFIG_FILE" "application_support_directories"
}

clean_custom_directories() {
  CUSTOM_DIRS_SECTION_EXISTS=$(jq 'has("custom_directories")' "$CONFIG_FILE")
  
  if [ "$CUSTOM_DIRS_SECTION_EXISTS" = "true" ]; then
    print_header "CUSTOM DIRECTORIES CLEANUP"
    print_info "Processing custom directories from configuration file"
    
    process_directory_section "$CONFIG_FILE" "custom_directories"
  else
    print_info "No custom directories specified in config."
  fi
}

# ==============================================
# iOS Cleanup Functions
# ==============================================
clean_simulators() {
  # Check if we should clean simulators
  CLEAN_SIMULATORS=$(jq -r '.device_support.clean_simulators // "true"' "$CONFIG_FILE")
  
  if [ "$CLEAN_SIMULATORS" = "true" ]; then
    print_subheader "Removing unavailable iOS simulators"
    print_info "This will remove simulators that are no longer available."
    
    if confirm "Do you want to remove unavailable simulators?"; then
      xcrun simctl delete unavailable
      print_success "Removed unavailable simulators"
    else
      print_info "Skipping simulator cleanup"
    fi
  else
    print_info "Simulator cleanup disabled in config"
  fi
}

clean_ios_device_support() {
  CLEAN_IOS_DEVICE_SUPPORT=$(jq -r '.device_support.clean_ios_device_support // "true"' "$CONFIG_FILE")
  KEEP_LATEST_IOS=$(jq -r '.device_support.keep_latest_ios_versions // 2' "$CONFIG_FILE")

  if [ "$CLEAN_IOS_DEVICE_SUPPORT" = "true" ]; then
    IOS_DEVICE_SUPPORT="$HOME/Library/Developer/Xcode/iOS DeviceSupport"
    print_subheader "Cleaning iOS Device Support"
    print_size "$IOS_DEVICE_SUPPORT"
    
    if [ -d "$IOS_DEVICE_SUPPORT" ]; then
      echo -e "${BLUE}Available iOS Device Support versions:${NC}"
      ls -la "$IOS_DEVICE_SUPPORT" | grep -v "^total" | grep -v "^d.*\.\.$"
      
      print_info "Config set to keep the latest $KEEP_LATEST_IOS iOS versions."
      
      # Get list of directories sorted by modification time (newest last)
      ios_versions=()
      while IFS= read -r line; do
        ios_versions+=("$line")
      done < <(get_sorted_directories "$IOS_DEVICE_SUPPORT" '^iPhone[0-9]+,[0-9]+ [0-9]+\.[0-9]+ \([0-9A-Z]+\)$')
      print_info "Available iOS Device Support versions: ${ios_versions[@]}"
      total_versions=${#ios_versions[@]}
      
      if [ $total_versions -le $KEEP_LATEST_IOS ]; then
        print_info "You have $total_versions iOS versions, which is less than or equal to the configured $KEEP_LATEST_IOS to keep. No cleanup needed."
      else
        # Calculate versions to remove (all except the latest KEEP_LATEST_IOS)
        to_remove=$((total_versions - KEEP_LATEST_IOS))
        print_info "Found $total_versions iOS versions, will remove $to_remove older versions"
        
        # Process the older versions (first in the array)
        for ((i=0; i<$to_remove; i++)); do
          version_dir="$IOS_DEVICE_SUPPORT/${ios_versions[$i]}"
          version_name="${ios_versions[$i]}"
          version_size=$(du -sh "$version_dir" 2>/dev/null | cut -f1)
          
          if confirm "Remove iOS Device Support for $version_name (Size: $version_size)?"; then
            if is_safe_path "$version_dir"; then
              rm -rf "$version_dir" 2>/dev/null
              if [ $? -eq 0 ]; then
                print_success "Removed iOS Device Support for $version_name"
              else
                print_error "Failed to remove iOS Device Support for $version_name"
              fi
            else
              print_warning "Skipping $version_dir due to safety check"
            fi
          else
            print_info "Keeping iOS Device Support for $version_name"
          fi
        done
      fi
    else
      print_info "iOS Device Support directory does not exist. Skipping."
    fi
  else
    print_info "iOS Device Support cleanup disabled in config"
  fi
}

clean_macos_device_support() {
  CLEAN_MACOS_DEVICE_SUPPORT=$(jq -r '.device_support.clean_macos_device_support // "true"' "$CONFIG_FILE")
  KEEP_LATEST_MACOS=$(jq -r '.device_support.keep_latest_macos_versions // 1' "$CONFIG_FILE")

  if [ "$CLEAN_MACOS_DEVICE_SUPPORT" = "true" ]; then
    MACOS_DEVICE_SUPPORT="$HOME/Library/Developer/Xcode/macOS DeviceSupport"
    print_subheader "Cleaning macOS Device Support"
    print_size "$MACOS_DEVICE_SUPPORT"
    
    if [ -d "$MACOS_DEVICE_SUPPORT" ]; then
      echo -e "${BLUE}Available macOS Device Support versions:${NC}"
      ls -la "$MACOS_DEVICE_SUPPORT" | grep -v "^total" | grep -v "^d.*\.\.$"
      
      print_info "Config set to keep the latest $KEEP_LATEST_MACOS macOS versions."
      
      # Get list of directories sorted by modification time (newest last)
      macos_versions=()
      while IFS= read -r line; do
        macos_versions+=("$line")
      done < <(get_sorted_directories "$MACOS_DEVICE_SUPPORT" '^[0-9]+\.[0-9]+$')
      print_info "Available macOS Device Support versions: ${macos_versions[@]}"
      total_versions=${#macos_versions[@]}
      
      if [ $total_versions -le $KEEP_LATEST_MACOS ]; then
        print_info "You have $total_versions macOS versions, which is less than or equal to the configured $KEEP_LATEST_MACOS to keep. No cleanup needed."
      else
        # Calculate versions to remove (all except the latest KEEP_LATEST_MACOS)
        to_remove=$((total_versions - KEEP_LATEST_MACOS))
        print_info "Found $total_versions macOS versions, will remove $to_remove older versions"
        
        # Process the older versions (first in the array)
        for ((i=0; i<$to_remove; i++)); do
          version_dir="$MACOS_DEVICE_SUPPORT/${macos_versions[$i]}"
          version_name="${macos_versions[$i]}"
          version_size=$(du -sh "$version_dir" 2>/dev/null | cut -f1)
          
          if confirm "Remove macOS Device Support for $version_name (Size: $version_size)?"; then
            if is_safe_path "$version_dir"; then
              rm -rf "$version_dir" 2>/dev/null
              if [ $? -eq 0 ]; then
                print_success "Removed macOS Device Support for $version_name"
              else
                print_error "Failed to remove macOS Device Support for $version_name"
              fi
            else
              print_warning "Skipping $version_dir due to safety check"
            fi
          else
            print_info "Keeping macOS Device Support for $version_name"
          fi
        done
      fi
    else
      print_info "macOS Device Support directory does not exist. Skipping."
    fi
  else
    print_info "macOS Device Support cleanup disabled in config"
  fi
}

# ==============================================
# Android Cleanup Functions
# ==============================================
clean_android_build_tools() {
  CLEAN_BUILD_TOOLS=$(jq -r '.android_sdk.clean_build_tools // "true"' "$CONFIG_FILE")
  ANDROID_SDK="$HOME/Library/Android/sdk"
  ANDROID_BUILD_TOOLS="$ANDROID_SDK/build-tools"

  if [ "$CLEAN_BUILD_TOOLS" = "true" ] && [ -d "$ANDROID_BUILD_TOOLS" ]; then
    print_subheader "Cleaning Android SDK Build Tools"
    print_size "$ANDROID_BUILD_TOOLS"
    
    echo -e "${BLUE}Available Android Build Tool versions:${NC}"
    ls -la "$ANDROID_BUILD_TOOLS" | grep -v "^total" | grep -v "^d.*\.\.$"
    
    print_warning "It's recommended to keep the latest Android build tools you actively use."
    
    # Get list of directories sorted by modification time (newest last)
    build_tool_versions=($(ls -t "$ANDROID_BUILD_TOOLS"))
    total_versions=${#build_tool_versions[@]}
    
    # Ask about keeping latest versions
    print_info "Found $total_versions Android build tool versions"
    read -p "$(echo -e ${YELLOW}How many of the latest versions do you want to keep? [Default: 2]${NC}) " keep_count
    
    # Default to 2 if no input
    keep_count=${keep_count:-2}
    
    if [ $total_versions -le $keep_count ]; then
      print_info "You have $total_versions build tool versions, which is less than or equal to $keep_count. No cleanup needed."
    else
      # Calculate versions to remove (all except the latest keep_count)
      to_remove=$((total_versions - keep_count))
      print_info "Will remove $to_remove older build tool versions"
      
      # Process the older versions (first in the array)
      for ((i=0; i<$to_remove; i++)); do
        version_dir="$ANDROID_BUILD_TOOLS/${build_tool_versions[$i]}"
        version_name="${build_tool_versions[$i]}"
        version_size=$(du -sh "$version_dir" 2>/dev/null | cut -f1)
        
        if confirm "Remove Android Build Tools version $version_name (Size: $version_size)?"; then
          if is_safe_path "$version_dir"; then
            rm -rf "$version_dir" 2>/dev/null
            if [ $? -eq 0 ]; then
              print_success "Removed Android Build Tools version $version_name"
            else
              print_error "Failed to remove Android Build Tools version $version_name"
            fi
          else
            print_warning "Skipping $version_dir due to safety check"
          fi
        else
          print_info "Keeping Android Build Tools version $version_name"
        fi
      done
    fi
  else
    if [ "$CLEAN_BUILD_TOOLS" != "true" ]; then
      print_info "Android Build Tools cleanup disabled in config"
    elif [ ! -d "$ANDROID_BUILD_TOOLS" ]; then
      print_info "Android Build Tools directory does not exist. Skipping."
    fi
  fi
}

clean_android_platforms() {
  CLEAN_PLATFORMS=$(jq -r '.android_sdk.clean_platforms // "true"' "$CONFIG_FILE")
  ANDROID_PLATFORMS="$ANDROID_SDK/platforms"

  if [ "$CLEAN_PLATFORMS" = "true" ] && [ -d "$ANDROID_PLATFORMS" ]; then
    print_subheader "Cleaning Android SDK Platforms"
    print_size "$ANDROID_PLATFORMS"
    
    echo -e "${BLUE}Available Android Platform versions:${NC}"
    ls -la "$ANDROID_PLATFORMS" | grep -v "^total" | grep -v "^d.*\.\.$"
    
    print_warning "It's recommended to keep the Android platforms you actively target."
    
    # Get list of directories sorted by modification time (newest last)
    platform_versions=($(ls -t "$ANDROID_PLATFORMS"))
    total_versions=${#platform_versions[@]}
    
    # Ask about keeping latest versions
    print_info "Found $total_versions Android platform versions"
    read -p "$(echo -e ${YELLOW}How many of the latest versions do you want to keep? [Default: 3]${NC}) " keep_count
    
    # Default to 3 if no input
    keep_count=${keep_count:-3}
    
    if [ $total_versions -le $keep_count ]; then
      print_info "You have $total_versions platform versions, which is less than or equal to $keep_count. No cleanup needed."
    else
      # Calculate versions to remove (all except the latest keep_count)
      to_remove=$((total_versions - keep_count))
      print_info "Will remove $to_remove older platform versions"
      
      # Process the older versions (first in the array)
      for ((i=0; i<$to_remove; i++)); do
        version_dir="$ANDROID_PLATFORMS/${platform_versions[$i]}"
        version_name="${platform_versions[$i]}"
        version_size=$(du -sh "$version_dir" 2>/dev/null | cut -f1)
        
        if confirm "Remove Android Platform $version_name (Size: $version_size)?"; then
          if is_safe_path "$version_dir"; then
            rm -rf "$version_dir" 2>/dev/null
            if [ $? -eq 0 ]; then
              print_success "Removed Android Platform $version_name"
            else
              print_error "Failed to remove Android Platform $version_name"
            fi
          else
            print_warning "Skipping $version_dir due to safety check"
          fi
        else
          print_info "Keeping Android Platform $version_name"
        fi
      done
    fi
  else
    if [ "$CLEAN_PLATFORMS" != "true" ]; then
      print_info "Android Platforms cleanup disabled in config"
    elif [ ! -d "$ANDROID_PLATFORMS" ]; then
      print_info "Android Platforms directory does not exist. Skipping."
    fi
  fi
}

clean_android_system_images() {
  CLEAN_SYSTEM_IMAGES=$(jq -r '.android_sdk.clean_system_images // "true"' "$CONFIG_FILE")
  ANDROID_SYSTEM_IMAGES="$ANDROID_SDK/system-images"

  if [ "$CLEAN_SYSTEM_IMAGES" = "true" ] && [ -d "$ANDROID_SYSTEM_IMAGES" ]; then
    print_subheader "Cleaning Android System Images"
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
                if is_safe_path "$image_type_dir"; then
                  rm -rf "$image_type_dir" 2>/dev/null
                  if [ $? -eq 0 ]; then
                    print_success "Removed Android $android_ver system image type $image_type"
                  else
                    print_error "Failed to remove Android system image"
                  fi
                else
                  print_warning "Skipping $image_type_dir due to safety check"
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
    if [ "$CLEAN_SYSTEM_IMAGES" != "true" ]; then
      print_info "Android System Images cleanup disabled in config"
    elif [ ! -d "$ANDROID_SYSTEM_IMAGES" ]; then
      print_info "Android System Images directory does not exist. Skipping."
    fi
  fi
}

# ==============================================
# General Cache Cleanup Functions
# ==============================================
clean_homebrew_cache() {
  CLEAN_HOMEBREW=$(jq -r '.cache_tools.clean_homebrew // "true"' "$CONFIG_FILE")

  if [ "$CLEAN_HOMEBREW" = "true" ] && check_command brew; then
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
  else
    if [ "$CLEAN_HOMEBREW" != "true" ]; then
      print_info "Homebrew cleanup disabled in config"
    elif ! command -v brew &> /dev/null; then
      print_info "Homebrew not installed. Skipping."
    fi
  fi
}

clean_cocoapods_cache() {
  CLEAN_COCOAPODS=$(jq -r '.cache_tools.clean_cocoapods // "true"' "$CONFIG_FILE")

  if [ "$CLEAN_COCOAPODS" = "true" ] && check_command pod; then
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
  else
    if [ "$CLEAN_COCOAPODS" != "true" ]; then
      print_info "CocoaPods cleanup disabled in config"
    elif ! command -v pod &> /dev/null; then
      print_info "CocoaPods not installed. Skipping."
    fi
  fi
}

# ==============================================
# Main Script
# ==============================================
main() {
  print_header "MAC DISK SPACE CLEANUP SCRIPT"
  print_info "This script will help you clean up disk space on your Mac."
  print_warning "It will ask for confirmation before deleting any files."
  
  # Check if a custom config file was specified
  if [ "$1" != "" ]; then
    CONFIG_FILE="$1"
    print_info "Using custom configuration file: $CONFIG_FILE"
  fi
  
  # Load configuration
  if ! load_config "$CONFIG_FILE"; then
    exit 1
  fi
  
  echo ""
  if ! confirm "Ready to proceed with the cleanup?"; then
    print_info "Cleanup cancelled by user."
    exit 0
  fi
  
  # Run cleanup sections
  clean_ios_developer
  clean_android_developer
  clean_general_cache
  clean_application_support
  clean_custom_directories
  
  print_header "CLEANUP COMPLETE"
  print_success "All cleanup operations have been completed."
}

# Run the main function
main "$@"