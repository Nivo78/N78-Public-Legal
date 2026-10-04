Imports System.Linq
Imports System.IO
Imports System.Net.Http
Imports System.Reflection
Imports System.Text
Imports System.Text.RegularExpressions
Imports System.Threading.Tasks

''' <summary>
''' N78-STD-LEGAL-01 WinForms: embedded baseline immediately; optional GitHub Pages canonical upgrade (never blocks display).
''' Canonical family copy — sync to Desktop\Nivo78\Common\WinForms via tools/sync-winforms-legal-snapshot.ps1
''' </summary>
Friend NotInheritable Class N78FamilyWinFormsLegalSnapshot
    Private Sub New()
    End Sub

    Friend Enum LegalDocKind
        Privacy
        Terms
    End Enum

    Private Shared ReadOnly Http As New HttpClient() With {
        .Timeout = TimeSpan.FromSeconds(12)
    }

    Friend Shared Function BundledBody(kind As LegalDocKind) As String
        Dim resourceSuffix =
            If(kind = LegalDocKind.Privacy, "privacy-baseline.txt", "terms-baseline.txt")
        Dim asm = Assembly.GetExecutingAssembly()
        For Each name In asm.GetManifestResourceNames()
            If name.EndsWith(resourceSuffix, StringComparison.OrdinalIgnoreCase) Then
                Using stream = asm.GetManifestResourceStream(name)
                    If stream Is Nothing Then
                        Exit For
                    End If
                    Using reader As New StreamReader(stream, Encoding.UTF8)
                        Dim text = reader.ReadToEnd()
                        If Not String.IsNullOrWhiteSpace(text) Then
                            Return text
                        End If
                    End Using
                End Using
            End If
        Next
        Return String.Empty
    End Function

    ''' <summary>Immediate text for legal UI (embedded snapshot).</summary>
    Friend Shared Function ActiveBody(kind As LegalDocKind) As String
        Dim bundled = BundledBody(kind)
        If Not String.IsNullOrWhiteSpace(bundled) Then
            Return bundled
        End If
        Return String.Empty
    End Function

    ''' <summary>GitHub canonical when reachable; otherwise embedded baseline. Never throws to caller.</summary>
    Friend Shared Function ReadingBody(kind As LegalDocKind, canonicalUrl As String) As String
        Dim fallback = ActiveBody(kind)
        Try
            Dim canonical = FetchCanonicalPlainTextOrNull(canonicalUrl)
            If Not String.IsNullOrWhiteSpace(canonical) Then
                Return canonical
            End If
        Catch
        End Try
        Return fallback
    End Function

    ''' <summary>Show embedded text immediately; replace with canonical on background success.</summary>
    Friend Shared Sub BeginReadingUpgrade(textBox As System.Windows.Forms.TextBox, kind As LegalDocKind, canonicalUrl As String)
        If textBox Is Nothing Then
            Return
        End If
        Dim initial = ActiveBody(kind)
        If Not String.IsNullOrWhiteSpace(initial) Then
            textBox.Text = initial
        End If
        If String.IsNullOrWhiteSpace(canonicalUrl) Then
            Return
        End If
        Task.Run(
            Sub()
                Dim body = ReadingBody(kind, canonicalUrl)
                If String.IsNullOrWhiteSpace(body) OrElse String.Equals(body, initial, StringComparison.Ordinal) Then
                    Return
                End If
                Try
                    If textBox.IsDisposed Then
                        Return
                    End If
                    textBox.BeginInvoke(
                        Sub()
                            If Not textBox.IsDisposed Then
                                textBox.Text = body
                            End If
                        End Sub)
                Catch
                End Try
            End Sub)
    End Sub

    Private Shared Function FetchCanonicalPlainTextOrNull(url As String) As String
        If String.IsNullOrWhiteSpace(url) Then
            Return Nothing
        End If
        Dim raw = Http.GetStringAsync(url).GetAwaiter().GetResult()
        If String.IsNullOrWhiteSpace(raw) Then
            Return Nothing
        End If
        Dim plain =
            If(raw.IndexOf("<html", StringComparison.OrdinalIgnoreCase) >= 0 OrElse
               raw.IndexOf("<body", StringComparison.OrdinalIgnoreCase) >= 0,
               HtmlToPlain(raw),
               raw.Trim())
        If String.IsNullOrWhiteSpace(plain) Then
            Return Nothing
        End If
        Return plain
    End Function

    Private Shared Function HtmlToPlain(html As String) As String
        Dim t = Regex.Replace(html, "(?s)<script.*?</script>", String.Empty, RegexOptions.IgnoreCase)
        t = Regex.Replace(t, "(?s)<style.*?</style>", String.Empty, RegexOptions.IgnoreCase)
        t = Regex.Replace(t, "<br\s*/?>", Environment.NewLine, RegexOptions.IgnoreCase)
        t = Regex.Replace(t, "</p>", Environment.NewLine & Environment.NewLine, RegexOptions.IgnoreCase)
        t = Regex.Replace(t, "</h[1-6]>", Environment.NewLine & Environment.NewLine, RegexOptions.IgnoreCase)
        t = Regex.Replace(t, "<li>", Environment.NewLine & "• ", RegexOptions.IgnoreCase)
        t = Regex.Replace(t, "<[^>]+>", String.Empty)
        t = System.Net.WebUtility.HtmlDecode(t)
        Dim lines =
            t.Split({ControlChars.Lf, ControlChars.Cr}, StringSplitOptions.RemoveEmptyEntries).
                Select(Function(line) line.Trim()).
                Where(Function(line) line.Length > 0)
        Return String.Join(Environment.NewLine, lines)
    End Function
End Class
