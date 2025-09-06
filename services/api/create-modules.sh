#!/bin/bash

# HaroonNet ISP Platform - Module Creation Script
# Creates basic module structure for all required modules

BASE_DIR="src/modules"

# Array of modules to create
MODULES=(
    "subscriptions"
    "billing"
    "payments"
    "tickets"
    "noc"
    "radius"
    "reports"
    "system"
    "notifications"
    "auth/guards"
    "auth/strategies"
    "auth/dto"
    "users/dto"
    "customers/dto"
)

# Create module directories and basic files
for module in "${MODULES[@]}"; do
    mkdir -p "$BASE_DIR/$module"

    # Extract module name (last part of path)
    module_name=$(basename "$module")

    # Skip subdirectories
    if [[ "$module" == *"/"* ]] && [[ "$module" != *"/dto" ]] && [[ "$module" != *"/guards" ]] && [[ "$module" != *"/strategies" ]]; then
        continue
    fi

    # Skip dto, guards, strategies directories
    if [[ "$module" == *"/dto" ]] || [[ "$module" == *"/guards" ]] || [[ "$module" == *"/strategies" ]]; then
        continue
    fi

    # Create module file if it doesn't exist
    if [[ ! -f "$BASE_DIR/$module/$module_name.module.ts" ]]; then
        cat > "$BASE_DIR/$module/$module_name.module.ts" << EOF
import { Module } from '@nestjs/common';

@Module({
  controllers: [],
  providers: [],
  exports: [],
})
export class ${module_name^}Module {}
EOF
    fi

    # Create service file
    if [[ ! -f "$BASE_DIR/$module/$module_name.service.ts" ]]; then
        cat > "$BASE_DIR/$module/$module_name.service.ts" << EOF
import { Injectable } from '@nestjs/common';

@Injectable()
export class ${module_name^}Service {
  // TODO: Implement service methods
}
EOF
    fi

    # Create controller file
    if [[ ! -f "$BASE_DIR/$module/$module_name.controller.ts" ]]; then
        cat > "$BASE_DIR/$module/$module_name.controller.ts" << EOF
import { Controller } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';

@ApiTags('${module_name^}')
@Controller('${module_name}')
export class ${module_name^}Controller {
  // TODO: Implement controller methods
}
EOF
    fi
done

echo "Module structure created successfully!"
