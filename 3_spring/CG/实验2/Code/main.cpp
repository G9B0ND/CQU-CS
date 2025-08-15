#include <GL/glew.h>
#include <GLFW/glfw3.h>
#include <cmath>

#include <imgui.h>
#include <imgui_impl_glfw.h>
#include <imgui_impl_opengl3.h>
#include <vector>

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif


// ���Ƶ�ṹ��
struct Point {
    float x, y;
    Point(float x = 0, float y = 0) : x(x), y(y) {}
};

// ȫ�ֱ���
std::vector<Point> controlPoints = { {100, 400}, {200, 400}, {300, 400}, {400, 400} };
int degree = 3;
int numSamples = 50;
float translateX = 0.0f, translateY = 0.0f;
float rotateAngle = 0.0f;
float scaleX = 1.0f, scaleY = 1.0f;
int selectedPoint = -1;
bool drawAsPoints = false; // Ĭ�����߶λ���
std::vector<float> knots;

// ����B����������
float BasisFunction(int i, int k, float t, const std::vector<float>& knots) {
    if (k == 0) {
        return (t >= knots[i] && t < knots[i + 1]) ? 1.0f : 0.0f;
    }

    float N1 = 0.0f;
    float denom1 = knots[i + k] - knots[i];
    if (denom1 != 0.0f) {
        float alpha = (t - knots[i]) / denom1;
        N1 = alpha * BasisFunction(i, k - 1, t, knots);
    }

    float N2 = 0.0f;
    float denom2 = knots[i + k + 1] - knots[i + 1];
    if (denom2 != 0.0f) {
        float beta = (knots[i + k + 1] - t) / denom2;
        N2 = beta * BasisFunction(i + 1, k - 1, t, knots);
    }

    return N1 + N2;
}

// ���ɾ��Ƚڵ�����
void GenerateUniformKnots() {
    knots.clear();
    int n = controlPoints.size() - 1;
    if (n < degree) return; // ��ֹ�Ƿ����
    int m = n + degree + 1;

    for (int i = 0; i <= degree; ++i) knots.push_back(0);
    for (int i = 1; i <= n - degree; ++i)
        knots.push_back(static_cast<float>(i) / (n - degree + 1));
    for (int i = 0; i <= degree; ++i) knots.push_back(1);
}

// ����B�������ߵ�
std::vector<Point> CalculateBSpline() {
    std::vector<Point> curvePoints;
    if (controlPoints.size() <= degree) return curvePoints;

    GenerateUniformKnots();
    float t_min = knots[degree];
    float t_max = knots[controlPoints.size()] - 1e-5f;  // ���� t == 1.0 β��ͻ��
    float step = (t_max - t_min) / numSamples;

    for (int s = 0; s <= numSamples; ++s) {
        float t = t_min + s * step;
        Point p(0, 0);

        for (int i = 0; i < controlPoints.size(); ++i) {
            float N = BasisFunction(i, degree, t, knots);
            p.x += controlPoints[i].x * N;
            p.y += controlPoints[i].y * N;
        }

        // ��ѡ��ֹ (0,0) ���������
        if (std::isfinite(p.x) && std::isfinite(p.y)) {
            curvePoints.push_back(p);
        }
    }

    return curvePoints;
}


// OpenGL��ͼ����
void DrawCurve(const std::vector<Point>& points) {
    glBegin(GL_LINE_STRIP);
    for (const auto& p : points) {
        glVertex2f(p.x, p.y);
    }
    glEnd();
}

// ���Ƶ����
void DrawControlPoints() {
    glPointSize(8.0f);
    glBegin(GL_POINTS);
    for (const auto& p : controlPoints) {
        glVertex2f(p.x, p.y);
    }
    glEnd();
}

// ���α任Ӧ��
void ApplyTransformations(std::vector<Point>& points) {
    float rad = rotateAngle * M_PI / 180.0f;
    for (auto& p : points) {
        // ����
        p.x *= scaleX;
        p.y *= scaleY;

        // ��ת
        float x = p.x * cos(rad) - p.y * sin(rad);
        float y = p.x * sin(rad) + p.y * cos(rad);
        p.x = x;
        p.y = y;

        // ƽ��
        p.x += translateX;
        p.y += translateY;
    }
}

int main() {
    // ��ʼ��GLFW
    if (!glfwInit()) return -1;
    GLFWwindow* window = glfwCreateWindow(800, 600, "B-Spline Editor", NULL, NULL);
    glfwMakeContextCurrent(window);
    glewInit();

    // ��ʼ��ImGui
    IMGUI_CHECKVERSION();
    ImGui::CreateContext();
    ImGui_ImplGlfw_InitForOpenGL(window, true);
    ImGui_ImplOpenGL3_Init("#version 330");

    // ��ѭ��
    while (!glfwWindowShouldClose(window)) {
        glfwPollEvents();

        // ImGui֡��ʼ
        ImGui_ImplOpenGL3_NewFrame();
        ImGui_ImplGlfw_NewFrame();
        ImGui::NewFrame();

        // �������
        ImGui::Begin("Control Panel");
        ImGui::SliderInt("Degree", &degree, 1, 5);
        ImGui::SliderInt("Samples", &numSamples, 10, 200);
        ImGui::Checkbox("Draw as Points", &drawAsPoints);

        // ���Ƶ���������
        static int numPoints = controlPoints.size();
        if (ImGui::InputInt("Control Points", &numPoints)) {
            numPoints = std::max(degree + 1, numPoints);
            controlPoints.resize(numPoints);
        }

        // ���α任
        ImGui::Separator();
        ImGui::InputFloat("Translate X", &translateX);
        ImGui::InputFloat("Translate Y", &translateY);
        ImGui::InputFloat("Rotate", &rotateAngle);
        ImGui::InputFloat("Scale X", &scaleX);
        ImGui::InputFloat("Scale Y", &scaleY);

        // ���Ƶ�����༭
        ImGui::Separator();
        ImGui::Text("Control Points:");
        for (int i = 0; i < controlPoints.size(); ++i) {
            ImGui::PushID(i);
            ImGui::SliderFloat2("P", &controlPoints[i].x, 0.0f, 800.0f);
            ImGui::PopID();
        }

        ImGui::End();

        // ��꽻�� - �϶����Ƶ�
        if (ImGui::IsMouseClicked(0)) {
            ImVec2 mousePos = ImGui::GetMousePos();
            int height;
            glfwGetFramebufferSize(window, nullptr, &height);
            float mouseY = mousePos.y;

            for (int i = 0; i < controlPoints.size(); ++i) {
                if (fabs(mousePos.x - controlPoints[i].x) < 8 &&
                    fabs(mouseY - controlPoints[i].y) < 8) {
                    selectedPoint = i;
                    break;
                }
            }
        }

        if (selectedPoint != -1 && ImGui::IsMouseDragging(0)) {
            ImVec2 delta = ImGui::GetMouseDragDelta(0);
            controlPoints[selectedPoint].x += delta.x;
            controlPoints[selectedPoint].y += delta.y;
            ImGui::ResetMouseDragDelta(0);
        }

        if (ImGui::IsMouseReleased(0)) {
            selectedPoint = -1;
        }

        // OpenGL��Ⱦ����
        glClear(GL_COLOR_BUFFER_BIT);
        glMatrixMode(GL_PROJECTION);
        glLoadIdentity();
        int width, height;
        glfwGetFramebufferSize(window, &width, &height);
        glOrtho(0, width, height, 0, -1, 1);

        // ��������
        std::vector<Point> curvePoints = CalculateBSpline();
        ApplyTransformations(curvePoints);

        glColor3f(184.0f / 255.0f, 71.0f / 255.0f, 77.0f / 255.0f);
        if (drawAsPoints) {
            glPointSize(4.0f);
            glBegin(GL_POINTS);
            for (const auto& p : curvePoints) {
                glVertex2f(p.x, p.y);
            }
            glEnd();
        }
        else {
            DrawCurve(curvePoints); // Ĭ���߶λ���
        }

        // ���Ƶ㼰����
        glColor3f(78.0f / 255.0f, 102.0f / 255.0f, 145.0f / 255.0f);
        DrawControlPoints();
        glBegin(GL_LINE_STRIP);
        for (const auto& p : controlPoints) {
            glVertex2f(p.x, p.y);
        }
        glEnd();

        // ��ȾImGui
        ImGui::Render();
        ImGui_ImplOpenGL3_RenderDrawData(ImGui::GetDrawData());

        glfwSwapBuffers(window);
    }

    // ����
    ImGui_ImplOpenGL3_Shutdown();
    ImGui_ImplGlfw_Shutdown();
    ImGui::DestroyContext();
    glfwTerminate();
    return 0;
}
