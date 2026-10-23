pragma Singleton
import QtQuick

QtObject {
    id: lang
    readonly property string language: backend.language

    function t(source) {
        return backend.translate(source, lang.language)
    }

    function f(source, values) {
        var result = t(source)
        if (values) {
            for (var key in values) {
                result = result.split("{" + key + "}").join(values[key])
            }
        }
        return result
    }
}
