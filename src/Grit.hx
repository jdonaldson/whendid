import sys.io.Process;
using StringTools;

class Grit {

    static function shell(cmd : String) : String {
        var p = new Process(cmd);
        var exit = p.exitCode(true);
        if (exit != 0){
            throw ('Error : ' + p.stderr.readAll().toString());
        }
        return p.stdout.readAll().toString().trim();
    }
    static function git(cmdstr : String) : String {
        var p = new Process('git $cmdstr');
        var exit = p.exitCode(true);
        if (exit != 0){
            var err = p.stderr.readAll().toString();
            var out = p.stdout.readAll().toString();
            var msg = err.length > 0 ? err : out;
            throw ('Error : $cmdstr\n Message: $msg');
        }
        return p.stdout.readAll().toString();
    }

    public static function commit(branch : String) : Void {
        git("add .");
        git('commit -m grit-$branch --quiet');
    }

    public static function isDirty() : Bool {
        var message = "nothing to commit, working tree clean";
        var status = git('status');
        var index = status.lastIndexOf(message);
        return index == -1;
    }
    public static function deleteGritTags(){
        shell("git tag -l grit-* | xargs git tag -d");
    }

    public static function log(metric : String, value : Float){
        var branch = git("rev-parse HEAD").substr(0,8);
        var payload = {branch : branch, metric : metric, value : value};
        var payload_str = haxe.Json.stringify(payload);
        payload_str = ~/"/g.replace(payload_str, "\\\"");

        if (isDirty()){
            commit(branch);
        }
        if (git('tag -l grit-$branch') == ""){
            git('tag -a grit-$branch -m "$payload_str"');
        } else {
            var current = shell('git show grit-$branch --quiet --format=%b | tail -n +4');
            current = ~/"/g.replace(current, "\\\"");
            if (current.indexOf(payload_str) == -1){
                current += '\n$payload_str';
                shell('git tag -fa grit-$branch -m "$current"');
            }
        }


    }

}

