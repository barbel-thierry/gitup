#!/bin/bash

# Configuration
MAX_DEPTH=3
CURRENT_DIR=$(pwd)

# Compteurs et listes
NO_UPDATE_COUNT=0
UPDATED_COUNT=0
UPDATED_LIST=()
IGNORED_COUNT=0
IGNORED_LIST=()
FAILED_COUNT=0
FAILED_LIST=()

# Couleurs pour le terminal
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Fonction pour obtenir la branche active
get_current_branch() {
    local dir="$1"
    git -C "$dir" rev-parse --abbrev-ref HEAD 2>/dev/null
}

# Fonction récursive de mise à jour
process_directory() {
    local dir="$1"
    local depth="$2"

    # 1. Vérifier si le dossier actuel est un repo
    local branch
    branch=$(get_current_branch "$dir")

    if [ -n "$branch" ]; then
        if [[ "$branch" == "main" || "$branch" == "master" ]]; then
            # Tenter le pull
            echo -e "  > ${BOLD}${dir}${NC} (${GREEN}${branch}${NC})..."

            result=$(git -C "$dir" pull --rebase 2>&1)

            if [[ $result == *"Already up to date."* ]]; then
                NO_UPDATE_COUNT=$((NO_UPDATE_COUNT + 1))
                echo -e "    ${GREEN}✔ Déjà à jour.${NC}"
            elif [[ $result == *"Updating"* ]]; then
                UPDATED_COUNT=$((UPDATED_COUNT + 1))
                UPDATED_LIST+=("$dir")
                echo -e "    ${GREEN}✔ Mis à jour avec succès.${NC}"
            elif [[ $result == *"error"* || $result == *"fatal"* ]]; then
                FAILED_COUNT=$((FAILED_COUNT + 1))
                FAILED_LIST+=("$dir")
                echo -e "    ${RED}✘ Échec de la mise à jour.${NC}"
                echo -e "    ${RED}$result${NC}"
            else
                echo "$result"
            fi
        else
            IGNORED_COUNT=$((IGNORED_COUNT + 1))
            IGNORED_LIST+=("$dir:$branch")
            echo -e "  ➖ ${YELLOW}${dir}${NC} (${YELLOW}${branch}${NC}) ignoré."
        fi
        return
    fi

    # 2. Si pas de repo, aller plus profond si max_depth n'est pas atteint
    if [ "$depth" -lt "$MAX_DEPTH" ]; then
        # Utilisation de shopt pour gérer les cas où aucun sous-dossier n'existe
        shopt -s nullglob
        local subdirs=("$dir"*/)
        shopt -u nullglob

        for subdir in "${subdirs[@]}"; do
            process_directory "$subdir" $((depth + 1))
        done
    fi
}

# --- Début du script principal ---

echo "🚀 Démarrage de la mise à jour des dépôts Git (main/master)..."
echo "-----------------------------------------------------------"

# Parcourir les dossiers de l'emplacement courant
for folder in */; do
    [ -d "$folder" ] || continue

    echo -e "\n📁 Analyse de : ${folder}"
    echo "-----------------------------------------------------------"

    process_directory "$folder" 0
    echo "-----------------------------------------------------------"
done

# --- Affichage du récapitulatif ---

echo -e "\n${BOLD}📊 RÉCAPITULATIF${NC}"
echo "-----------------------------------------------------------"

if [ ${UPDATED_COUNT} -gt 0 ]; then
    echo -e "${GREEN}✔ Repositories mis à jour : ${UPDATED_COUNT}${NC}"
    for item in "${UPDATED_LIST[@]}"; do
        echo "   - $item"
    done
    echo "-----------------------------------------------------------"
fi

if [ ${IGNORED_COUNT} -gt 0 ]; then
    echo -e "${YELLOW}➖ Repositories ignorés : ${IGNORED_COUNT}${NC}"
    for item in "${IGNORED_LIST[@]}"; do
        echo "   - $item (mauvaise branche)"
    done
    echo "-----------------------------------------------------------"
fi

if [ ${FAILED_COUNT} -gt 0 ]; then
    echo -e "${RED}✘ Échecs : ${FAILED_COUNT}${NC}"
    for item in "${FAILED_LIST[@]}"; do
        echo "   - $item"
    done
    echo "-----------------------------------------------------------"
fi

TOTAL=$((NO_UPDATE_COUNT + UPDATED_COUNT + IGNORED_COUNT + FAILED_COUNT))
echo -e "${BOLD}📈 Total dépôts traités : ${TOTAL}${NC}"
echo "-----------------------------------------------------------"
echo -e "${GREEN}✅ Opération terminée.${NC}"
