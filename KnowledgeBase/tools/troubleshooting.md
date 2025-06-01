# Xcode Troubleshooting Guide

## Common Build Errors

### "No such module" Error
1. Clean build folder (Shift+Cmd+K)
2. Delete derived data
3. Close Xcode
4. Run: `rm -rf ~/Library/Developer/Xcode/DerivedData`
5. Reopen project

### Code Signing Issues
1. Check Signing & Capabilities tab
2. Ensure correct team selected
3. Automatic signing recommended for development

### Simulator Issues
- Reset simulator: Device > Erase All Content and Settings
- Clean build after reset

## Performance Issues

### Slow Builds
- Enable build timing: Product > Perform Action > Build With Timing Summary
- Check for expensive type inference
- Consider modularizing large projects

### Memory Issues
- Use Instruments for memory profiling
- Check for retain cycles in closures
- Use weak/unowned appropriately