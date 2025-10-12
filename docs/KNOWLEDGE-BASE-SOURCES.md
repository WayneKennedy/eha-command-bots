# Knowledge Base Data Sources & Maintenance

## The Problem

AI knowledge bases can become outdated quickly. Star Citizen receives frequent patches that add/remove locations, change mechanics, and update content. **We need reliable, up-to-date sources to keep the knowledge base accurate.**

**Recent Example:**
- ❌ Port Olisar (removed in Alpha 3.20, June 2023)
- ✅ Seraphim Station (replaced Port Olisar)
- ❌ "Port Olisar, Seraphim Station" listed (wrong - only 3 L-points have stations)

## Reliable Data Sources

### 1. Official Sources (Highest Priority)

#### Star Citizen Wiki (starcitizen.tools)
- **URL**: https://starcitizen.tools/
- **Reliability**: ⭐⭐⭐⭐⭐ Excellent
- **Update Frequency**: Within hours of patches
- **Maintained By**: Community, verified by players
- **Use For**: Locations, stations, ships, mechanics

**Key Pages:**
- Locations: https://starcitizen.tools/Category:Locations
- Crusader: https://starcitizen.tools/Crusader
- Stanton: https://starcitizen.tools/Stanton_system
- Ships: https://starcitizen.tools/Category:Ships

**API Access:**
- API Documentation: https://starcitizen.tools/Star_Citizen_Wiki:Application_programming_interface
- Can be queried programmatically for automated updates

#### Star Citizen Wiki API
- **URL**: https://api.star-citizen.wiki/
- **Documentation**: https://docs.star-citizen.wiki/
- **Reliability**: ⭐⭐⭐⭐⭐ Excellent
- **Update Frequency**: Real-time with wiki updates
- **Use For**: Automated knowledge base validation

**Benefits:**
- Free API access with registration
- Near-unlimited rate limiting
- Scrapes Comm-Links, stats, and in-game data
- JSON format responses

#### Roberts Space Industries (Official Site)
- **URL**: https://robertsspaceindustries.com/
- **Galactapedia**: https://robertsspaceindustries.com/galactapedia
- **Reliability**: ⭐⭐⭐⭐⭐ Official source
- **Update Frequency**: Official announcements only
- **Use For**: Lore, official announcements, ship stats

**Note:** Galactapedia sometimes lags behind actual game state.

### 2. Community Databases (Secondary Sources)

#### SCUnpacked
- **URL**: https://github.com/richardthombs/scunpacked
- **Reliability**: ⭐⭐⭐⭐ Very good
- **Update Frequency**: With each game patch
- **Use For**: Game file data, items, ships, locations

**Benefits:**
- Parses actual game files
- JSON API available
- Most up-to-date item/ship stats

#### FleetYards.net
- **URL**: https://fleetyards.net/
- **Reliability**: ⭐⭐⭐⭐ Very good
- **Update Frequency**: Weekly
- **Use For**: Ship information, station locations

#### Star Citizen Fandom Wiki
- **URL**: https://starcitizen.fandom.com/
- **Reliability**: ⭐⭐⭐ Good (but check starcitizen.tools first)
- **Update Frequency**: Variable
- **Use For**: Cross-reference only

### 3. Community Resources

#### /r/starcitizen (Reddit)
- **URL**: https://reddit.com/r/starcitizen
- **Reliability**: ⭐⭐⭐ Good for patch notes
- **Use For**: Patch announcements, community verification

#### Spectrum (Official Forums)
- **URL**: https://robertsspaceindustries.com/spectrum
- **Use For**: Official patch notes, dev responses

## Recommended Update Workflow

### Manual Updates (Current Approach)

**After Each Major Patch:**

1. **Check Patch Notes**
   - Read official patch notes: https://robertsspaceindustries.com/comm-link
   - Look for: New locations, removed locations, system changes

2. **Verify on starcitizen.tools**
   - Cross-reference changes with wiki
   - Check "Recent changes" page
   - Read location-specific pages

3. **Update knowledge-base/star-citizen-universe.yml**
   - Add new locations
   - Remove deprecated locations
   - Update status (in_development → playable)
   - Update version number and last_verified date

4. **Test with Officers**
   - Ask officers about new/changed locations
   - Verify they don't reference removed locations
   - Check mission generation uses correct locations

5. **Commit to Git**
   ```bash
   git add knowledge-base/star-citizen-universe.yml
   git commit -m "Update universe KB: Alpha 3.24.x patch"
   git push
   ```

### Semi-Automated Updates (Future Enhancement)

**Using Star Citizen Wiki API:**

```python
# scripts/update-universe-kb.py
import requests
import yaml

def fetch_stanton_locations():
    """Fetch current Stanton system locations from API"""
    api_url = "https://api.star-citizen.wiki/api/v1/systems/stanton"
    response = requests.get(api_url)
    return response.json()

def update_knowledge_base():
    """Update YAML with latest data"""
    # Fetch current data
    current_data = fetch_stanton_locations()

    # Load existing KB
    with open('knowledge-base/star-citizen-universe.yml', 'r') as f:
        kb = yaml.safe_load(f)

    # Compare and flag differences
    differences = compare_data(kb['systems']['stanton'], current_data)

    if differences:
        print("⚠️  Knowledge base out of date:")
        for diff in differences:
            print(f"  - {diff}")
        print("\nReview and update knowledge-base/star-citizen-universe.yml")
    else:
        print("✅ Knowledge base up to date")

# Run weekly via cron
update_knowledge_base()
```

## Update Schedule

### High Priority Updates (Immediate)
- New systems released (Pyro full release, Nyx launch)
- Major locations added/removed (stations, landing zones)
- Current operations area changes

### Medium Priority Updates (Within 1 week)
- New ships/vehicles released
- Gameplay mechanics changes
- Faction changes

### Low Priority Updates (Monthly review)
- Minor location changes
- Lore updates
- Terminology clarifications

## Current Corrections Needed

### ❌ Errors Found in star-citizen-universe.yml

1. **Port Olisar**
   - Status: REMOVED (Alpha 3.20, June 2023)
   - Replaced by: Seraphim Station
   - Fix: Remove Port Olisar, add Seraphim Station

2. **Crusader Lagrange Stations**
   - Current in game: CRU-L1, CRU-L4, CRU-L5 only
   - CRU-L2 and CRU-L3: Do not exist
   - Fix: Update to only list L1, L4, L5

3. **Station Names**
   - CRU-L1: "Ambitious Dream Station"
   - CRU-L4: "Shallow Fields Station"
   - CRU-L5: "Beautiful Glen Station"
   - Fix: Add full names with proper formatting

### Verification Checklist

Before updating KB, verify from **at least 2 sources**:

- [ ] Check starcitizen.tools wiki page
- [ ] Verify in-game (if possible)
- [ ] Cross-reference with community (Reddit, Spectrum)
- [ ] Check API if available

## Automated Validation (Future)

### Concept: CI/CD Knowledge Base Validation

```yaml
# .github/workflows/validate-kb.yml
name: Validate Knowledge Base

on:
  schedule:
    - cron: '0 0 * * 1'  # Weekly on Monday
  workflow_dispatch:      # Manual trigger

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Fetch SC Wiki API data
        run: python scripts/fetch-sc-data.py

      - name: Compare with knowledge base
        run: python scripts/validate-kb.py

      - name: Create issue if outdated
        if: failure()
        uses: actions/github-script@v6
        with:
          script: |
            github.rest.issues.create({
              owner: context.repo.owner,
              repo: context.repo.repo,
              title: '⚠️ Knowledge Base Outdated',
              body: 'Automated check found differences between KB and current game state. Review scripts/validation-report.txt'
            })
```

## Version Tracking

### Current Knowledge Base Status

| File | Last Updated | Game Version | Verified Against |
|------|--------------|--------------|------------------|
| star-citizen-universe.yml | 2025-10-11 | Alpha 3.24.x | ⚠️ **Needs Update** (Port Olisar error) |
| eha-organization.yml | 2025-10-11 | N/A | ✅ Current |

### Update History

```yaml
# Add to bottom of star-citizen-universe.yml
update_history:
  - date: "2025-10-12"
    game_version: "Alpha 3.24.x"
    changes:
      - "Fixed Port Olisar (removed, replaced with Seraphim Station)"
      - "Fixed Crusader stations (L1, L4, L5 only)"
      - "Added proper station names"
    verified_against: "starcitizen.tools"
    verified_by: "Wayne"
```

## Best Practices

### DO:
✅ Check starcitizen.tools wiki before updates
✅ Verify with at least 2 sources
✅ Update version tracking when changing KB
✅ Test with officers after updates
✅ Document sources in commit messages
✅ Update after major patches
✅ Keep update_history in YAML files

### DON'T:
❌ Trust AI-generated location data without verification
❌ Use outdated sources (old YouTube videos, old Reddit posts)
❌ Skip testing after updates
❌ Forget to update game_version field
❌ Make assumptions about locations/features

## Community Contribution

### For Open Source Contributors

When contributing KB updates:

1. **Cite Your Sources**
   ```
   Update Crusader station info

   - Removed Port Olisar (removed in 3.20)
   - Added Seraphim Station
   - Fixed L-point stations

   Sources:
   - https://starcitizen.tools/Crusader
   - https://starcitizen.tools/Port_Olisar
   - Verified in-game Alpha 3.24.1
   ```

2. **Include Game Version**
   - Always note which game version you're playing
   - Alpha 3.24.x, PTU 3.25, etc.

3. **Cross-Reference**
   - Link to wiki pages
   - Screenshot if needed (for new content)
   - Verify with community

## Resources Summary

### Quick Links

| Resource | URL | Use For |
|----------|-----|---------|
| **SC Tools Wiki** | https://starcitizen.tools/ | Primary source |
| **SC Wiki API** | https://api.star-citizen.wiki/ | Automation |
| **API Docs** | https://docs.star-citizen.wiki/ | API reference |
| **Galactapedia** | https://robertsspaceindustries.com/galactapedia | Lore |
| **Patch Notes** | https://robertsspaceindustries.com/comm-link | Updates |
| **SCUnpacked** | https://github.com/richardthombs/scunpacked | Game files |
| **FleetYards** | https://fleetyards.net/ | Ships/Stations |

---

**Next Steps:**
1. Fix current errors in star-citizen-universe.yml
2. Implement update tracking in YAML
3. Create validation script (optional)
4. Set up weekly review schedule
