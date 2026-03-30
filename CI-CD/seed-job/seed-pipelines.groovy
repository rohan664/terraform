import groovy.json.JsonSlurper
import groovy.io.FileType

// ------------------- CONFIG -------------------

def env = "qa"

// ------------------- READ FILES -------------------
def folderConfig = new JsonSlurper().parseText(
    readFileFromWorkspace("seed-pipeline/${env}/folder.json")
)

def authConfig = new JsonSlurper().parseText(
    readFileFromWorkspace("seed-pipeline/${env}/config.json")
)

// ------------------- CREATE FOLDERS -------------------
def perms = authConfig[env]

folderConfig.folders.each { f ->
    // def fldPath = f.path.split("/")[-1]
    // def folderPerms = perms[fldPath] ?: []
    folder(f.path) {
            authorization {
                perms.each { entry ->
                    entry.permissions.each { p ->
                        userPermission("hudson.model.Item.${p}", entry.name)
                    }
                }
            }
            description(f.description ?: "")
        }
}

// ------------------- UTILITY -------------------
String toFolderName(File file, File baseDir) {
    def relative = file.parentFile.path.replace(baseDir.path, "").replace("\\", "/")
    if (relative.startsWith("/")) relative = relative.substring(1)
    return relative  // e.g., "frontend" or "backend"
}


// ------------------- FIND JOB FILES -------------------
def folderConsider = ["build","deploy"]
folderConsider.each { fld -> 
    def buildBaseDir = new File("${WORKSPACE}/${fld}/${env}")
    def jobFiles = []

    buildBaseDir.eachFileRecurse(FileType.FILES) { f ->
        if (f.name.endsWith(".yml") || f.name.endsWith(".groovy")) {
            jobFiles << f
        }
    }

    // ------------------- GENERATE JOBS -------------------
    jobFiles.each { File file ->

        def module = toFolderName(file, buildBaseDir)
        def jobName = file.name.replaceAll(/\.(yml|groovy)$/, "")
        def folderPath = "${fld}/${env}/${module}"

        pipelineJob("${folderPath}/${jobName}") {

            // -------- JOB DEFINITION --------
            definition {
                cps {
                    script(file.text)
                    sandbox(true)
                }
            }
        }

        println "Created pipeline job: ${folderPath}/${jobName}"
    }

}

