export GITHUB_WORKSPACE=/home/baptiste/github.com/BapRx/changelogs
export REPOSITORY=prometheus-community/helm-charts
export TYPE=helm
rm -rf ${GITHUB_WORKSPACE}/_changelogs/*
find . -type f -name Changelog.md -not -empty | while read line; do
    dn=$(dirname $line)
    fn=$(basename $dn)
    if [ ! -d "${GITHUB_WORKSPACE}/_changelogs/${TYPE}/" ]; then
        mkdir "${GITHUB_WORKSPACE}/_changelogs/${TYPE}/"
        echo -e "---\nredirect_from:\n  - /\nhas_children: true\n---\n# ${TYPE}\n" >"${GITHUB_WORKSPACE}/_changelogs/${TYPE}/index.md"
    fi
    if [ ! -d "${GITHUB_WORKSPACE}/_changelogs/${TYPE}/${REPOSITORY//\//_}/" ]; then
        mkdir "${GITHUB_WORKSPACE}/_changelogs/${TYPE}/${REPOSITORY//\//_}/"
        echo -e "---\nparent: ${TYPE}\nhas_children: true\n---\n# ${REPOSITORY}\n" >"${GITHUB_WORKSPACE}/_changelogs/${TYPE}/${REPOSITORY//\//_}/index.md"
    fi
    cp $line "${GITHUB_WORKSPACE}/_changelogs/${TYPE}/${REPOSITORY//\//_}/$fn.md"
    sed -i '1i---\nrender_with_liquid: false\nparent: '${REPOSITORY}'\ngrand_parent: '${TYPE}'\n---\n' "${GITHUB_WORKSPACE}/_changelogs/${TYPE}/${REPOSITORY//\//_}/$fn.md"
    sed -i "s/^# Change Log$/# $fn/" "${GITHUB_WORKSPACE}/_changelogs/${TYPE}/${REPOSITORY//\//_}/$fn.md"
done
