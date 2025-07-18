import Map "mo:base/HashMap";
import Text "mo:base/Text";
import Iter "mo:base/Iter";
import Array "mo:base/Array";
import Principal "mo:base/Principal";
import Nat "mo:base/Nat";
import ProjectTypes "../types/ProjectTypes";

module ProjectStorage {

    type Project = ProjectTypes.Project;
    type ProjectStatus = ProjectTypes.ProjectStatus;

    public class ProjectStore() {

        // Storage for projects
        private var projectsEntries : [(Text, Project)] = [];
        private var projects = Map.fromIter<Text, Project>(projectsEntries.vals(), projectsEntries.size(), Text.equal, Text.hash);

        // Counter for generating project IDs
        private var projectCounter : Nat = 0;

        // System functions for upgrades
        public func preupgrade() : [(Text, Project)] {
            Iter.toArray(projects.entries());
        };

        public func postupgrade(entries : [(Text, Project)]) {
            projects := Map.fromIter<Text, Project>(entries.vals(), entries.size(), Text.equal, Text.hash);
        };

        // Generate unique project ID
        public func generateProjectId() : Text {
            projectCounter += 1;
            "PROJECT-" # Nat.toText(projectCounter);
        };

        // Store project
        public func putProject(projectId : Text, project : Project) {
            projects.put(projectId, project);
        };

        // Get project by ID
        public func getProject(projectId : Text) : ?Project {
            projects.get(projectId);
        };

        // Get projects by founder ID
        public func getProjectsByFounder(founderId : Text) : [Project] {
            let foundProjects = Array.filter<Project>(
                projects.vals() |> Iter.toArray(_),
                func(project : Project) : Bool {
                    project.founderId == founderId;
                },
            );
            foundProjects;
        };

        // Get projects by founder principal
        public func getProjectsByFounderPrincipal(principal : Principal) : [Project] {
            let foundProjects = Array.filter<Project>(
                projects.vals() |> Iter.toArray(_),
                func(project : Project) : Bool {
                    project.founderPrincipal == principal;
                },
            );
            foundProjects;
        };

        // Get projects by status
        public func getProjectsByStatus(status : ProjectStatus) : [Project] {
            let foundProjects = Array.filter<Project>(
                projects.vals() |> Iter.toArray(_),
                func(project : Project) : Bool {
                    project.status == status;
                },
            );
            foundProjects;
        };

        // Get projects by type
        public func getProjectsByType(projectType : ProjectTypes.ProjectType) : [Project] {
            let foundProjects = Array.filter<Project>(
                projects.vals() |> Iter.toArray(_),
                func(project : Project) : Bool {
                    project.projectType == projectType;
                },
            );
            foundProjects;
        };

        // Search projects by tags
        public func searchProjectsByTags(searchTags : [Text]) : [Project] {
            let foundProjects = Array.filter<Project>(
                projects.vals() |> Iter.toArray(_),
                func(project : Project) : Bool {
                    // Check if project has any of the search tags
                    Array.find<Text>(
                        searchTags,
                        func(searchTag : Text) : Bool {
                            Array.find<Text>(
                                project.tags,
                                func(projectTag : Text) : Bool {
                                    Text.contains(projectTag, #text searchTag) or Text.contains(searchTag, #text projectTag);
                                },
                            ) != null;
                        },
                    ) != null;
                },
            );
            foundProjects;
        };

        // Get all projects
        public func getAllProjects() : [Project] {
            projects.vals() |> Iter.toArray(_);
        };

        // Get project count
        public func getProjectCount() : Nat {
            projects.size();
        };

        // Update project
        public func updateProject(projectId : Text, project : Project) : Bool {
            switch (projects.get(projectId)) {
                case null { false };
                case (?_) {
                    projects.put(projectId, project);
                    true;
                };
            };
        };

        // Delete project
        public func deleteProject(projectId : Text) : Bool {
            switch (projects.remove(projectId)) {
                case null { false };
                case (?_) { true };
            };
        };

        // Check if project exists
        public func projectExists(projectId : Text) : Bool {
            switch (projects.get(projectId)) {
                case null { false };
                case (?_) { true };
            };
        };

        // Get projects with pagination
        public func getProjectsPaginated(offset : Nat, limit : Nat) : [Project] {
            let allProjects = projects.vals() |> Iter.toArray(_);
            let totalProjects = allProjects.size();

            if (offset >= totalProjects) {
                return [];
            };

            let endIndex = if (offset + limit > totalProjects) {
                totalProjects;
            } else {
                offset + limit;
            };

            Array.subArray<Project>(allProjects, offset, endIndex - offset);
        };
    };
};
